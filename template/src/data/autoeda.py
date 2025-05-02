# NOTE ydata-profiling
import numpy as np
import pandas as pd
from ydata_profiling import ProfileReport

df = pd.DataFrame(np.random.rand(100, 5), columns=["a", "b", "c", "d", "e"])
profile = ProfileReport(df, title="Profiling Report")



# NOTE https://github.com/man-group/dtale
import dtale
import pandas as pd

df = pd.DataFrame([dict(a=1,b=2,c=3)])

# Assigning a reference to a running D-Tale process.
d = dtale.show(df)


# NOTE https://github.com/AutoViML/AutoViz
from autoviz import AutoViz_Class
AV = AutoViz_Class()
dft = AV.AutoViz(filename)
