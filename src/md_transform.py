import sys
import subprocess

#FIXME unable to line with a star that is not a text modifier

# --- Modificators ---

RESET = r'\e[0m'
BOLD = r'\e[1m'
ITALICS = r'\e[3m'
UNDERLINE = r'\e[4m'

NOCOLOR= r'\033[0m'
RED = r'\033[0;31m'
GREEN = r'\033[0;32m'

# list is not exhaustive 
prefixes = [' ', '\n', '(', ':', '$', '>', '/', ')', ']', UNDERLINE]
suffixes = [' ', '\n', ')', ':', '.', '!', '?', '/', ',', RESET]

# start with the biggest patterns
modif_start = {'***': BOLD + ITALICS,
                '**': BOLD,
                '*': ITALICS
              }
            
modif_end = {'***': RESET,
              '**': RESET,
              '*': RESET
            }

# --- Titles ---

MAX_TITLE_LEVEL = 5
MIN_SUBTITLE_LEVEL = 3
TITLE_SEPARATOR = ') '
INNER_SUBTITLE_SEPARATOR = '.'

titles_format_start = {}
titles_format_end = {}

titles_format_start[0] = lambda index: BOLD + 'ヽ(o＾▽＾o)ノ ' + UNDERLINE
titles_format_end[0] = RESET + BOLD + ' ヽ(・∀・)ﾉ ' + RESET

titles_format_start[1] = lambda index: UNDERLINE + BOLD + chr(ord('A') + index - 1)
titles_format_end[1] = RESET

titles_format_start[2] = lambda index: UNDERLINE + ITALICS + f'{index}'
titles_format_end[2] = RESET

titles_format_start[3] = lambda index: UNDERLINE + chr(ord('a') + index - 1)
titles_format_end[3] = RESET

titles_format_start[4] = lambda index: UNDERLINE + f'{index}'
titles_format_end[4] = RESET


def generate_modificators():
  
  modificators = {}

  for prefix in prefixes:
      for mod_md, mod_print in modif_start.items():
        pattern_md = prefix + mod_md
        pattern_print = prefix + mod_print
        modificators[pattern_md] = pattern_print

  for suffix in suffixes:
      for mod_md, mod_print in modif_end.items():
        pattern_md = mod_md + suffix
        pattern_print = mod_print + suffix
        modificators[pattern_md] = pattern_print

  return modificators


def convert_md_to_printable(md_text, translate_dict):
  output_str = ""
  tmp_row = ""
  md_rows = md_text.split('\n')

  for md_r in md_rows:
    output_str += '\n'
    check_row = md_r.split('*')
    if len(check_row) % 2 == 0: # TODO star parsing will fail
      output_str += md_r
      # print(f"odd number of stars, passing line:\n{md_r}")
      continue
    else:
      previous_row = md_r
      for md_pattern, print_pattern in translate_dict.items(): # key, value
        tmp_row = previous_row.replace(md_pattern, print_pattern)
        if tmp_row != previous_row:
          # print(previous_row)
          # print(f"changed '{md_pattern}' to '{print_pattern}' in :")
          # print(tmp_row)
          previous_row = tmp_row

      output_str += tmp_row

  return output_str

def format_title(title, level, count, parents={}):
  formatted_str = ''
  if parents != {}:
    for parent_level, parent_count in parents.items():
      formatted_str += titles_format_start[parent_level](parent_count)
      formatted_str += INNER_SUBTITLE_SEPARATOR + RESET

    formatted_str += RESET
  
  formatted_str += titles_format_start[level](count)
  if level > 0: formatted_str += TITLE_SEPARATOR
  formatted_str += title + titles_format_end[level]
  # print(formatted_str)
  return formatted_str

def format_titles(md_text):
  titles_count = {}
  for t in range(MAX_TITLE_LEVEL):
    titles_count[t] = 0

  md_formatted = ''
  md_rows = md_text.split('\n')
  first_line = True

  for md_r in md_rows:
    if first_line:
      first_line = False
    else:
      md_formatted += '\n'
    
    if len(md_r) == 0:
      continue

    if (len(md_r) > 2 and md_r[:4] == '  ') or (len(md_r) > 4 and md_r[:4] == '    '): # code
      without_spaces = md_r.replace('  ', GREEN)
      with_color_format = GREEN + without_spaces.replace('#',  NOCOLOR + '#')
      md_formatted += with_color_format + NOCOLOR # ensure color reset on code line without comment
      continue

    index = 0

    if md_r[index] != '#':
      md_formatted += md_r
    
    elif len(md_r) > 1: # title
      title_level = 0
      for index in range(1, MAX_TITLE_LEVEL + 1):  # subtitle
        if md_r[index] != '#':
          title_level = index - 1
          new_title_count = titles_count[title_level] + 1
          # print(f"title_level={title_level}, new_title_count={new_title_count}")
          titles_count[title_level] = new_title_count
          if md_r[index] != ' ':
            index -= 1 # no space to remove
          break
      
      if title_level < MIN_SUBTITLE_LEVEL:
        md_formatted += format_title(md_r[index+1:], title_level, new_title_count)

      else: # display parent titles indexes
        parents = {lvl: titles_count[lvl] for lvl in range(MIN_SUBTITLE_LEVEL - 1, title_level)}
        md_formatted += format_title(md_r[index+1:], title_level, new_title_count, parents=parents)
        # md_formatted += f'{RESET} {title_level}-{new_title_count}: {titles_count}'

      if title_level <= MIN_SUBTITLE_LEVEL:
        for lvl in range(title_level + 1, MAX_TITLE_LEVEL):
          titles_count[lvl] = 0
    
  return md_formatted

def print_md_file(md_file):
  with open(md_file, 'r') as file:
    md_text = file.read()

  md_formatted = format_titles(md_text)

  modificators = generate_modificators()
  printable_string = convert_md_to_printable(md_formatted, modificators)
  
  command = f'echo -e "{printable_string}"'
  subprocess.Popen(command, shell=True)


if __name__ == '__main__':
  try:
    parse = False
    name_of_script = sys.argv[0]
    option = sys.argv[1]
    if option == '-t' or option == '--target':
      md_target = sys.argv[2]
      parse = True
  except IndexError: # no markdown target passed in params
    print("absent or invalid target passed as argument")
  
  if parse:
    print_md_file(md_target)
