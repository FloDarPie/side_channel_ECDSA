import seaborn as sns
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import matplotlib.transforms as trans
import numpy as np
import pandas as pd
import math
import sys
import traceback
import glob
import os

data_folder = 'results/'
image_folder = 'images/'
name_sep = '_'

exit_on_index_error = False
display_dataframe = False

def as_output(input_path, p_val, q_val, style):
  return input_path.replace('*.csv', '') + f"{p_val}_{q_val}_{style}.png"

def display_data(dataframe):
  print(dataframe.dtypes)
  print("\n")
  print(dataframe)

def array_as_string(array, separator=', '):
  result = ''
  m = len(array) - 1
  for i in range(m):
    result += array[i] + separator
    
  result += array[m]
  return result

def separe_folder_from_file(path):
  splited = str(path).split('/')
  folder = splited[-2]
  file = splited[-1]
  return folder, file

def get_last_folder():
  folder_pattern = data_folder + "*/"
  list_of_folders = glob.glob(folder_pattern)
  latest_folder = max(list_of_folders, key=os.path.getmtime)
  latest_folder = latest_folder.replace(data_folder, '') # remove prefix
  # print(latest_folder)
  return latest_folder

def get_all_matching_files(pattern):
  file_pattern = data_folder + pattern
  list_of_files = glob.glob(file_pattern)
  # print(list_of_files)
  return list_of_files

styles = ['scatterplots','logt_size', 'epsi_time', 'pairplot', 'best'] # TODO tab of avg values

best_style = 'scatterplots'

default_datafile = 'last'
default_output = 'show'

usage = "usage: python3 result_plotter.py [style] [input_path] [output]\n"
usage += "\tstyle can be: " + array_as_string(styles) + "\n"
usage += "\tdata_folder=" + data_folder + " ; image_folder=" + image_folder + "\n"

params = ["name_of_script", "style", "input_path", "output"]

index = 0
try:
  name_of_script = sys.argv[index]
  index += 1
  style = str(sys.argv[index])
  index += 1
  input_path = str(sys.argv[index])
  index += 1
  output = str(sys.argv[index])
  index += 1
except IndexError:
  print(usage)
  print("IndexError (some params are missing), first param missing: " + params[index])
  if exit_on_index_error:
    print(traceback.format_exc())
    sys.exit()
  if (index <= 1): style = best_style
  if (index <= 2): input_path = default_datafile
  if (index <= 3): output = default_output

if style == 'best':
  style = best_style
elif style not in styles:
  print(f"selected style ({style}) should be on of the following: " + array_as_string(styles) + "\n")
  style = best_style

if input_path == '' or input_path == 'last':
  input_path = get_last_folder() + "*.csv"

matching_files = get_all_matching_files(input_path)
nb_datafiles = len(matching_files)
if nb_datafiles > 1:
  folder, wildcard = separe_folder_from_file(input_path)
  print(f"folder={folder}")
  print(f"wildcard={wildcard}")
  try:
    hostname, y, m, d, h, m = folder.split(name_sep)
  except ValueError:
    print(f"Failed to parse folder={folder} with separator='{name_sep}' and recover info")
    print(traceback.format_exc())
    exit(1)

parse_result = "style=" + style
# parse_result+= "\nmatching_files=" + array_as_string(matching_files)
parse_result+= "\noutput=" + output + "\n"
print(parse_result)

p_last, q_last = None, None

df = pd.DataFrame({})
for matching_file in matching_files:
  _, datafile = separe_folder_from_file(matching_file)
  print(datafile)
  try:
    split = datafile.split(name_sep) # filename = f"{domain}/{p_q}_{algo}_{index}.csv"
    p_val, q_val, *algo_used, repetition = datafile.split(name_sep)
    algo_used = array_as_string(algo_used, '-')
    # print(algo_used)
    repetition = "".join(repetition.split('.')[:-1])
  except ValueError:
    print(f"Failed to parse datafile={datafile} with separator='{name_sep}' and recover info")
    print(traceback.format_exc())
    exit(1)
  
  if p_last != None and q_last != None:
    if p_last != p_val:
      raise ValueError(f"p_val ({p_val}) != p_last ({p_last}) : incoherent dataset")
    if q_last != q_val:
      raise ValueError(f"q_val ({q_val}) != q_last ({q_last}) : incoherent dataset")

  p_last, q_last = p_val, q_val

  df_add = pd.read_csv(matching_file, sep=' ; ', engine ='python')
  df_add['algo'] = [str(algo_used) for i in range(len(df_add))]

  df_add['log10time'] = [ math.log(t, 10) for t in df_add['time (sec)'] ]

  df = pd.concat([df, df_add]).reset_index(drop=True)

df_types_dict = {'epsilon': float, 
                  'nb messages': int, 
                  'time (sec)': float,
                  'correct': bool}

df = df.astype(df_types_dict)

# TODO merge lines with same algorithms and parameters to get a mean value

if display_dataframe:
   display_data(df)

df_invalid_key_indexes = df[(df['correct'] == False)].index
df.drop(df_invalid_key_indexes, inplace = True)

figure_title = input_path

match style:

  case 'logt_size':
    
    sns.color_palette("colorblind")
    df_invalid_key_indexes = df[(df['correct'] == False)].index
    df.drop(df_invalid_key_indexes, inplace = True)

    nb_algos = len(pd.unique(df['algo']))
    markers_dict = {0:'X', 1:'^', 2:'v', 3:'H', 4:'d', 5:'*', 6:'s', 7:'o'}
    if nb_algos < len(markers_dict):
      markers = [markers_dict[i] for i in range(nb_algos)] # keeping best markers
    else:
      markers = None

    sns.set_style("whitegrid")
    sns.relplot(
      data=df,
      x='epsilon', 
      y='nb messages',
      hue='algo',
      style='algo',
      markers=markers,
      size='log10time',
      alpha=0.6
    )
    bbox = trans.Bbox.from_bounds(-0.25, 0, 6.5, 5.5) # (xmin, ymin, width, height)

  case 'scatterplots':
    nb_epsilon = len(pd.unique(df['epsilon']))
    # print("nb_epsilon", nb_epsilon)
    palette = sns.color_palette("husl", nb_epsilon)
    sns.set_style("whitegrid")
    g = sns.FacetGrid(df, col="algo", hue="epsilon", palette=palette)
    plt.yscale('log')

    g.set_titles(col_template="algo={col_name}")
    # g.map(sns.scatterplot, 'nb messages', 'log10time', alpha=0.7)
    g.map(sns.scatterplot, 'nb messages', 'time (sec)', alpha=0.7)
    nb_cols = max(3, nb_epsilon // 11)
    g.add_legend(ncol=nb_cols)
    # g.fig.suptitle(figure_title, va='bottom')

    # bbox = trans.Bbox.from_bounds(0, 0, 12, 3) # (xmin, ymin, width, height)

    #plt.title(figure_title, loc='bottom') # , fontsize=12)

  case 'epsi_time':

    sns.set_theme(style="whitegrid")

    g = sns.lineplot(data=df, 
    x='epsilon', 
    y='time (sec)', 
    hue='algo',
    style='algo'#, markers=['+', 'x', '1']
    )
    g.set(yscale='log')

  case 'pairplot':

    sns.set_theme(style="whitegrid")
    df = df.drop(columns=['time (sec)', 'correct'])

    g = sns.pairplot(df, hue="algo", plot_kws={"s": 3})#, diag_kind="hist", markers=["o", "s", "D"])

  case _:
    raise ValueError("style=%s is not in styles=%s" % (style, array_as_string(styles)))


if output == '' or output == 'auto': # FIXME assert that every p is the same in data set
  output = as_output(input_path, p_val, q_val, style)

if output == 'show':
  plt.show()
else:
  save_file = image_folder + output
  print(f"Saving plot at: {save_file}")
  os.makedirs(os.path.dirname(save_file), exist_ok=True)
  plt.savefig(save_file)#, bbox_inches=bbox)