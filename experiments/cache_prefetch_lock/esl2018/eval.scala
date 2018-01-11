// Process emulation output for generation of bar charts

import scala.sys.process._
import java.io._
import scala.collection.mutable
import scala.io.Source

val log = args.length == 0

val types = List("np", "sp")
val cache = List("mcache", "icache", "pcache", "lcache")

val np = Map("mcache" -> mutable.Map[String, Int](), "icache" -> mutable.Map[String, Int](), "pref" -> mutable.Map[String, Int]())
val sp = Map("mcache" -> mutable.Map[String, Int](), "icache" -> mutable.Map[String, Int](), "pcache" -> mutable.Map[String, Int](), "lcache" -> mutable.Map[String, Int]())

val all = Map("np" -> np, "sp" -> sp)

val bench = mutable.Set[String]()

val files = new File(".").listFiles
val txtFiles = files.filter( f => f.getName.endsWith(".txt") )
txtFiles.map{ file => addResult(file.getName) }

def addResult(f: String) {
  val s = Source.fromFile(f)
  val l = s.getLines()
  val v = l.next().split(" ")
  bench += v(0)
  val cycles = l.next().split(" ")(1).toInt
  if (log) println(v.toList + ": " + cycles)
  all(v(2))(v(1)) += (v(0) -> cycles)
}

if (log) println()
if (log) println(bench)

def printStat(t: String) {
  println("Results for " + t + ": mcache icache")
  val sortedBench = bench.toSeq.sorted
  for (b <- sortedBench) {
    val v1 = all(t)("mcache")(b)
    val v2 = all(t)("icache")(b)
    val fac = v2.toDouble / v1
    println(b + " " + v1 + " " + v2 + " " + fac)
  }
}


// execution time in cycles therefore v2/v1 normalizes to v2
def printData(t: String, c1: String, c2: String) {
  println("sym y")
  val sortedBench = bench.toSeq.sorted
  var geoMean: Double = 1
  for (b <- sortedBench) {
    val v1 = all(t)(c1)(b)
    val v2 = all(t)(c2)(b)
    val fac = v2.toDouble / v1
    val n = b.flatMap { case '_' => "\\_" case c => s"$c" }
    println(n + " " + fac)
    geoMean = geoMean * fac
  }
  // println("geom. mean: " + scala.math.pow(geoMean,1./sortedBench.size))
}

if (log) types.map{ t => printStat(t) }

if (!log) printData(args(0), args(1), args(2))