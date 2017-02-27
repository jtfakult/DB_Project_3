Just put this readme together really quick as a notice to anyone compiling this program:

Compiing this on the CCC gave me a compatability warning between java 6 and 7.
you may come across the error: Exception in thread "main" java.lang.UnsupportedClassVersionError: Reporting : Unsupported major.minor version 51.0
To fix this run the following javac code:
COMPILE WITH: javac -source 1.6 -target 1.6 *.java
