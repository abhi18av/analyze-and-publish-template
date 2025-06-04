
import matlab.engine
eng = matlab.engine.start_matlab('-desktop')

pd = {'milk': 3.50, 'bread': 2.50, 'eggs': 2.75}
md = matlab.dictionary(pd)

eng.workspace['md'] = md

eng.quit()



   import matlab.engine

   # Start MATLAB engine
   eng = matlab.engine.start_matlab()

   # Example: Load a sequence alignment file (e.g., FASTA format)
   alignment = eng.readseq('')

   # Display the alignment
   print(alignment)

   # Stop the MATLAB engine
   eng.quit()
