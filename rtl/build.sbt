ThisBuild / scalaVersion := "2.13.10"
ThisBuild / version      := "0.1.0"

lazy val root = (project in file("."))
  .settings(
    name := "intent-v-rtl",
    libraryDependencies ++= Seq(
      "edu.berkeley.cs" %% "chisel3"    % "3.6.0",
      "edu.berkeley.cs" %% "chiseltest" % "0.6.2" % "test"
    ),
    scalacOptions ++= Seq("-deprecation", "-feature", "-unchecked",
      "-language:reflectiveCalls", "-Xcheckinit"),
    addCompilerPlugin("edu.berkeley.cs" % "chisel3-plugin" % "3.6.0" cross CrossVersion.full)
  )
