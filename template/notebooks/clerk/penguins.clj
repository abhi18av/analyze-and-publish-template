;; # Exploring the Palmer Penguins Dataset with Clojure
;;
;; This notebook explores the famous Palmer Penguins dataset using Clojure and Clerk.

^{:nextjournal.clerk/visibility {:code :show :result :show}}
(ns penguins-exploration
  (:require [nextjournal.clerk :as clerk]
            [clojure.data.csv :as csv]
            [clojure.java.io :as io]
            [clojure.string :as str]
            [tablecloth.api :as tc]
            [tech.v3.dataset :as ds]
            [tech.v3.datatype :as dtype]
            [scicloj.kindly.v4 :as kindly]
            [scicloj.noj.v1.vis.hanami :as hanami]))

;; ## Data Loading
;; First, let's download the Palmer Penguins dataset if we don't have it already

^{:nextjournal.clerk/visibility {:code :show :result :hide}}
(def penguins-url "https://raw.githubusercontent.com/allisonhorst/palmerpenguins/master/inst/extdata/penguins.csv")

(defn fetch-penguins-data []
  (let [temp-file (java.io.File/createTempFile "penguins" ".csv")]
    (with-open [in (io/input-stream penguins-url)
                out (io/output-stream temp-file)]
      (io/copy in out))
    temp-file))

(def penguins-file (fetch-penguins-data))

;; Now let's load the data into a dataset
(def penguins
  (-> penguins-file
      (tc/dataset {:key-fn keyword})
      (tc/drop-missing)))

;; ## Dataset Overview
;; Let's take a look at the first few rows of our dataset

^{:nextjournal.clerk/visibility {:code :show :result :show}}
(clerk/table (tc/head penguins 5))

;; Let's check the dataset structure and summary statistics

(clerk/table (tc/info penguins))

;; ## Basic Summary Statistics

(clerk/table (tc/summary penguins))

;; ## Dataset Exploration
;;
;; Let's count the penguins by species

(def species-counts
  (-> penguins
      (tc/group-by [:species])
      (tc/aggregate {:count tc/row-count})
      (tc/order-by [:count] :desc)))

^{:nextjournal.clerk/visibility {:code :show :result :show}}
(clerk/table species-counts)

;; Visualize species distribution

^{:nextjournal.clerk/visibility {:code :show :result :show}}
(clerk/vl
  {:data {:values (tc/rows species-counts :as-maps)}
   :mark "bar"
   :encoding {:x {:field "species", :type "nominal"}
              :y {:field "count", :type "quantitative"}
              :color {:field "species", :type "nominal"}}
   :width 400
   :height 300})

;; ## Exploring Penguin Features
;;
;; Let's look at relationships between body measurements by species

;; Body mass distribution by species
^{:nextjournal.clerk/visibility {:code :show :result :show}}
(clerk/vl
  {:data {:values (tc/rows penguins :as-maps)}
   :mark "boxplot"
   :encoding {:x {:field "species", :type "nominal"}
              :y {:field "body_mass_g", :type "quantitative"}
              :color {:field "species", :type "nominal"}}
   :width 500
   :height 300})

;; Relationship between bill length and bill depth, colored by species
^{:nextjournal.clerk/visibility {:code :show :result :show}}
(clerk/vl
  {:data {:values (tc/rows penguins :as-maps)}
   :mark "point"
   :encoding {:x {:field "bill_length_mm", :type "quantitative"}
              :y {:field "bill_depth_mm", :type "quantitative"}
              :color {:field "species", :type "nominal"}}
   :width 500
   :height 400})

;; ## Islands Distribution
;;
;; Let's look at how the penguin species are distributed across islands

(def island-species-counts
  (-> penguins
      (tc/group-by [:island :species])
      (tc/aggregate {:count tc/row-count})))

^{:nextjournal.clerk/visibility {:code :show :result :show}}
(clerk/table island-species-counts)

;; Visualize species distribution by island
^{:nextjournal.clerk/visibility {:code :show :result :show}}
(clerk/vl
  {:data {:values (tc/rows island-species-counts :as-maps)}
   :mark "bar"
   :encoding {:x {:field "island", :type "nominal"}
              :y {:field "count", :type "quantitative"}
              :color {:field "species", :type "nominal"}}
   :width 500
   :height 300})

;; ## Correlation Analysis
;;
;; Let's examine correlations between numerical features

(def numeric-cols [:bill_length_mm :bill_depth_mm :flipper_length_mm :body_mass_g])

(defn correlation-matrix [dataset columns]
  (let [data (tc/select-columns dataset columns)
        cols (tc/column-names data)]
    (reduce (fn [acc col1]
              (reduce (fn [acc' col2]
                        (let [corr (tc/correlation data col1 col2)]
                          (assoc acc' [col1 col2] corr)))
                      acc
                      cols))
            {}
            cols)))

(def corr-matrix (correlation-matrix penguins numeric-cols))

;; Format correlation matrix for visualization
(def corr-data
  (for [col1 numeric-cols
        col2 numeric-cols]
    {:x (name col1)
     :y (name col2)
     :correlation (get corr-matrix [col1 col2])}))

;; Visualize the correlation matrix as a heatmap
^{:nextjournal.clerk/visibility {:code :show :result :show}}
(clerk/vl
  {:data {:values corr-data}
   :mark "rect"
   :encoding {:x {:field "x", :type "nominal"}
              :y {:field "y", :type "nominal"}
              :color {:field "correlation",
                      :type "quantitative",
                      :scale {:domain [-1, 1], :scheme "blueorange"}}
              :tooltip [{:field "correlation", :type "quantitative", :format ".2f"}]}
   :width 400
   :height 400})

;; ## Conclusion
;;
;; In this notebook, we've explored the Palmer Penguins dataset using Clojure and Clerk:
;;
;; - We found three penguin species: Adelie, Gentoo, and Chinstrap
;; - Analyzed their physical measurements and distributions across islands
;; - Discovered correlations between physical features
;; - Visualized the relationships between different measurements
;;
;; This dataset provides a great example for classification tasks, as the species are
;; fairly well separated by their physical characteristics.
#+end_src
