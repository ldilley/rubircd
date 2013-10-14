#!/bin/sh
# $Id$

# Use the line below for a safe experience (letting the JVM decide what's best)
jruby --server -J-Djruby.thread.pool.enabled=true rubircd.rb

# Use the line below for a highly-optimized experience
#jruby --fast --server -J-Xss256K -J-Xmn8M -J-Xms16M -J-Xmx64M -J-XX:PermSize=16M -J-XX:MaxPermSize=64M -J-Xincgc -J-Djruby.compile.invokedynamic=true -J-Djruby.thread.pool.enabled=true rubircd.rb
