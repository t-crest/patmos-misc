
class CacheSet:
    """A cache set with LRU replacement policy."""
    def __init__(self, associativity=4):
        self.associativity = associativity
        self.blocks = associativity * [None]

    def __str__(self):
        return "[" + "|".join([str(tag) if tag else "-"
                               for tag in self.blocks]) + "]"

    def contains(self, tag):
        return tag in self.blocks

    def update(self, tag):
        """LRU update the cache given a tag.

        Returns True on cache hit, False otherwise.
        """
        if tag in self.blocks:
            # Move tag to the front
            self.blocks.insert(0, self.blocks.pop(self.blocks.index(tag)))
            return True
        else:
            # Insert at the front and throw away the last element
            self.blocks.insert(0, tag)
            self.blocks.pop()
            return False


###############################################################################

class RPTEntry:
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)


class RPT_plain:
    """Reference Prediction Table (RPT).

    The RPT holds (immutable) data to program the prefetcher.
    It is composed from the primary table where all triggering lines are
    entered and a set of sub- (or secondary) tables, one for each prefetch
    type.

    the mk*() methods provide a convenient interface for new entries.
    """

    def __init__(self):
        self.rpt_primary = []
        self.rpt_loop    = []
        self.rpt_smloop  = []
        self.rpt_call    = []
        self.rpt_ret     = []
        self.rpt_any     = []

    def __len__(self):
        """Returns the number of rows in the RPT."""
        return len(self.rpt_primary)

    def nameof(self, subtab):
        """Given a reference to a subtable, returns the name of the table.

        Example: subtab=self.rpt_loop -> "LOOP"
        """
        return next(name[4:].upper() for name, ref in self.__dict__.items()
                    if ref == subtab)

    def _mkentry(self, trig, subtab, **kwargs):
        """Entry in the RPT (and subtables)"""
        pidx = len(self.rpt_primary)
        self.rpt_primary.append(
            RPTEntry(trig=trig, subtab=subtab, tidx=len(subtab)))
        subtab.append(RPTEntry(**kwargs))
        return pidx

    def mkloop(self, trig, dest, it, nxt):
        return self._mkentry(trig, self.rpt_loop,
                             dest=dest, it=it, nxt=nxt)

    def mksmloop(self, trig, it, count, nxt):
        return self._mkentry(trig, self.rpt_smloop,
                             it=it, count=count, nxt=nxt)

    def mkcall(self, trig, dest, retidx, retdest, nxt):
        return self._mkentry(trig, self.rpt_call,
                             dest=dest, retidx=retidx, retdest=retdest,
                             nxt=nxt)

    def mkret(self, trig):
        return self._mkentry(trig, self.rpt_ret)

    def mkany(self, trig, dest, nxt):
        return self._mkentry(trig, self.rpt_any,
                             dest=dest, nxt=nxt)

    def get_row(self, pidx):
        rpt_prim = self.rpt_primary[pidx]
        rpt_sub = rpt_prim.subtab[rpt_prim.tidx]
        return rpt_prim, rpt_sub

    def get_row_dict(self, pidx):
        prim, sek = self.get_row(pidx)
        d = dict(prim.__dict__)
        d["idx"]  = pidx
        d["type"] = self.nameof(prim.subtab)
        del d["subtab"], d["tidx"]
        d.update(sek.__dict__)
        return d


    def dump(self):
        print "Primary:"
        print "trig", "type", "tidx"
        for idx, row in enumerate(self.rpt_primary):
            print idx, row.trig, self.nameof(row.subtab), row.tidx
        print "Loops:"
        print "tidx", "dest", "it", "nxt"
        for tidx, row in enumerate(self.rpt_loop):
            print tidx, row.dest, row.it, row.nxt

###############################################################################



    #rpt = RPT_plain()
    #rpt.mkloop(1, 10, 123, 1)
    #rpt.mkloop(2, 20, 124, 321)
    #rpt.dump()
    #
    #for i in range(len(rpt)):
    #    print rpt.get_row_dict(i)
