## boggle-solver
A _fully functional_ [xquery 3.1](https://www.w3.org/XML/Group/qtspecs/specifications/xquery-31/html/xquery-31-diff.html) implementation to solve the [boggle game](https://en.wikipedia.org/wiki/Boggle).  
[James](//github.com/phraemer "@phraemer") brought this up at a coffee break as a mental exercise and we twisted the challenge a bit to implement it using a functional language. The primary language of choice was clojure, but at the time just started learning it and had a lot more experience with xml processing languages (like: xpath/xquery/xslt).  
   
TODO: 
  * optimize trie creation - currently takes the most of the time (is implemented in a pure functional way and creates a lot of xpath maps internally) - on the other hand is a nice use case for xquery engine optimization
  * serialize the generated trie as json and save it for reuse
  * time it with different xquery engines/implementations
  * would be nice to do some analysis on the distribution of the number of total words, words of different length and points per game (would require to ensure that the pseudo-random-function in the specific implementation has also a more or less uniform distribution)
  * implement it in clojure (and maybe python)
