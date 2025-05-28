#!/usr/bin/env bb

(require '[clojure.java.io :as io]
         '[clojure.string :as str])

(defn list-directory-contents
  "Return full paths of all files and directories in the given directory."
  [directory]
  (try
    (map #(.getPath %) (.listFiles (io/file directory)))
    (catch Exception _ [])))

(defn is-directory?
  "Check if a path points to a directory."
  [path]
  (.isDirectory (io/file path)))

(defn should-prune?
  "Check if a directory contains only a .gitkeep file."
  [directory]
  (let [contents (list-directory-contents directory)]
    (and (= (count contents) 1)
         (.isFile (io/file (first contents)))
         (= (.getName (io/file (first contents))) ".gitkeep"))))

(defn remove-file
  "Remove a file from the filesystem."
  [file-path]
  (try
    (io/delete-file file-path)
    (println "Deleted file:" file-path)
    (catch Exception e
      (println "Failed to delete file:" file-path "Error:" (.getMessage e)))))

(defn remove-directory
  "Remove a directory from the filesystem."
  [dir-path]
  (try
    (.delete (io/file dir-path))
    (println "Removed directory:" dir-path)
    (catch Exception e
      (println "Failed to remove directory:" dir-path "Error:" (.getMessage e)))))

(defn prune-directory
  "Recursively prune a directory."
  [directory]
  (let [contents (filter is-directory? (list-directory-contents directory))]
    (doseq [subdir contents]
      (prune-directory subdir))

    (when (should-prune? directory)
      (remove-file (str directory "/.gitkeep"))
      (remove-directory directory))))

(defn get-directories-to-scan
  "Get directories to scan from command line args or use default."
  [args]
  (if (empty? args)
    ["./"] ; Default directory is current directory
    (str/split (first args) #",")))

(defn -main [& args]
  (let [directories (get-directories-to-scan args)]
    (println "Scanning directories:" (str/join ", " directories))
    (doseq [dir directories]
      (println "Processing directory:" dir)
      (prune-directory dir))
    (println "Directory pruning complete.")))

(-main *command-line-args*)
