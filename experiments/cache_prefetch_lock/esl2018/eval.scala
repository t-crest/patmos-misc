// Process emulation output for generation of bar charts

import scala.sys.process._
import java.io._
import scala.collection.mutable
import scala.io.Source

val log = args.length == 0

//val types = List("np", "sp")
val types = List("sp")
//val cache = List("mcache", "icache", "pcache", "lcache")
val cache = List("mcache", "icache", "pcache")
val sizes = List("1024", "2048", "4096", "8192")

val group = Map("1024" -> mutable.Map[String, Int](), "2048" -> mutable.Map[String, Int](), "4096" -> mutable.Map[String, Int](), "8192" -> mutable.Map[String, Int]())

//val np = Map("mcache" -> mutable.Map[String, Int](), "icache" -> mutable.Map[String, Int](), "pref" -> mutable.Map[String, Int]())
//val sp = Map("mcache" -> mutable.Map[String, Int](), "icache" -> mutable.Map[String, Int](), "pcache" -> mutable.Map[String, Int](), "lcache" -> mutable.Map[String, Int]())

val sp = Map("mcache" -> group, "icache" -> group, "pcache" -> group)

//val all = Map("np" -> np, "sp" -> sp)
val all = Map("sp" -> sp)

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
//  all(v(2))(v(1)) += (v(0) -> cycles)
  all(v(2))(v(1))(v(3)) += (v(0) -> cycles)
}

if (log) println()
if (log) println(bench)
println(all)

def printStat(t: String) {
  println("Results for " + t + ": mcache icache")
  val sortedBench = bench.toSeq.sorted
  for (b <- sortedBench) {
    val v1 = all(t)("mcache")("1024")(b)
    val v2 = all(t)("icache")("1024")(b)
    val fac = v2.toDouble / v1
    println(b + " " + v1 + " " + v2 + " " + fac)
  }
}


// execution time in cycles therefore v2/v1 normalizes to v2
def printData(t: String, c1: String, c2: String) {
  println("sym 1k 2k 4k 8k")
  val sortedBench = bench.toSeq.sorted
  var geoMean: Double = 1
  for (b <- sortedBench) {
    val v11 = all(t)(c1)("1024")(b)
    val v21 = all(t)(c2)("1024")(b)
    val fac1 = v21.toDouble / v11
    val v12 = all(t)(c1)("2048")(b)
    val v22 = all(t)(c2)("2048")(b)
    val fac2 = v22.toDouble / v12
    val v14 = all(t)(c1)("4096")(b)
    val v24 = all(t)(c2)("4096")(b)
    val fac4 = v24.toDouble / v14
    val v18 = all(t)(c1)("8192")(b)
    val v28 = all(t)(c2)("8192")(b)
    val fac8 = v28.toDouble / v18
    val n = b.flatMap { case '_' => "\\_" case c => s"$c" }
    println(n + " " + fac1 + " " + fac2 + " " + fac4 + " " + fac8)
//    geoMean = geoMean * fac
  }
  // println("geom. mean: " + scala.math.pow(geoMean,1./sortedBench.size))
}

if (log) types.map{ t => printStat(t) }

if (!log) printData(args(0), args(1), args(2))
