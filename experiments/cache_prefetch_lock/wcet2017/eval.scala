
println("Hello from Scala")

import scala.sys.process._
import java.io._
import scala.collection.mutable
import scala.io.Source

val types = List("normal", "sp")
val cache = List("mcache", "icache", "pref")

val np = Map("mcache" -> mutable.Map[String, Int](), "icache" -> mutable.Map[String, Int](), "pref" -> mutable.Map[String, Int]())
val sp = Map("mcache" -> mutable.Map[String, Int](), "icache" -> mutable.Map[String, Int](), "pref" -> mutable.Map[String, Int]())

// TODO: switch to np in text generation
val all = Map("normal" -> np, "sp" -> sp)

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
  println(v.toList + ": " + cycles)
  all(v(2))(v(1)) += (v(0) -> cycles)
}

println()
println(bench)

def printStat(t: String) {
  println("Results for " + t + ": mcache icache")
  for (b <- bench) {
    val v1 = all(t)("mcache")(b)
    val v2 = all(t)("icache")(b)
    val fac = v2.toDouble / v1
    println(b + " " + v1 + " " + v2 + " " + fac)
  }
}

types.map{ t => printStat(t) }

