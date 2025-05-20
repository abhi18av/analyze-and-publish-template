(ns src.clerkbook)

(require '[nextjournal.clerk :as clerk])

(clerk/serve! {:browse?     true
               :watch-paths ["notebooks/clerk"]})

(nextjournal.clerk/show! 'nextjournal.clerk.tap)

(tap> (clerk/html [:h1 "Hello 🚰 Tap Inspector 👋"]))

(def clojure-data
  {:hello "world 👋"
   :tacos (map #(repeat % '🌮) (range 1 30))
   :zeta  "The\npurpose\nof\nvisualization\nis\ninsight,\nnot\npictures."})

(tap> clojure-data)
