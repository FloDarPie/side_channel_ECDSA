import sys
import subprocess
import traceback
import numpy as np
from datetime import datetime
import time

load("../impl_99.sage")

usage = "usage: python3 run_some_atk.py\ \n"
usage += "\t[epsilon_min] [epsilon_max] [epsilon_nb_samples]\ \n"
usage += "\t[n_min], [n_max], [n_step]\n"

params = ["name_of_script"]
params += ["epsilon_min", "epsilon_max", "epsilon_nb_samples"]
params += ["n_min", "n_max", "n_step"]

exit_on_index_error = False # exit if some params are missing
exit_on_value_error = True # exit if a convertion failed

default_epsilon_min = 0.1
default_epsilon_max = 0.2
default_epsilon_nb_samples = 2 # number of points in interval (epsilon values)
default_n_min = 5
default_n_max = 15
default_n_step = 5 # third param of range(.)

nb_params_success = 7
index = 0
try:
  name_of_script = sys.argv[index]
  if sys.argv[index] == "parameters.csv":
    subprocess.run(["sage", "run_full_atk.py"])
    exit()
  index += 1
  epsilon_min = float(sys.argv[index])
  index += 1
  epsilon_max = float(sys.argv[index])
  index += 1
  epsilon_nb_samples = int(sys.argv[index])
  index += 1
  n_min = int(sys.argv[index])
  index += 1
  n_max = int(sys.argv[index])
  index += 1
  n_step = int(sys.argv[index])
  index += 1
except ValueError:
  print(usage)
  print("ValueError (a convertion failed), buggous param parsed: " + params[index])
  if exit_on_value_error:
    print(traceback.format_exc())
    sys.exit()
  else:
    print("Using default params\n")
  if (index <= 1): epsilon_min = default_epsilon_min
  if (index <= 2): epsilon_max = default_epsilon_max
  if (index <= 3): epsilon_nb_samples = default_epsilon_nb_samples
  if (index <= 4): n_min = default_n_min
  if (index <= 5): n_max = default_n_max
  if (index <= 6): n_step = default_n_step
except IndexError:
  print(usage)
  print("IndexError (some params are missing), first param missing: " + params[index])
  if exit_on_index_error:
    print(traceback.format_exc())
    sys.exit()
  if (index <= 1): epsilon_min = default_epsilon_min
  if (index <= 2): epsilon_max = default_epsilon_max
  if (index <= 3): epsilon_nb_samples = default_epsilon_nb_samples
  if (index <= 4): n_min = default_n_min
  if (index <= 5): n_max = default_n_max
  if (index <= 6): n_step = default_n_step
else:
  print("all params succesfully parsed.\n")

if epsilon_min > epsilon_max:
  raise ValueError("epsilon_min (%f) should be smaller than epsilon_max (%f)" % (epsilon_min, epsilon_max))

if epsilon_nb_samples < 1:
  raise ValueError("epsilon_nb_samples (%i) should be greater than 1 (it's nb of epsilon values)" % (epsilon_nb_samples))

if n_min > n_max:
  raise ValueError("n_min (%i) should be smaller than n_max (%i)" % (n_min, n_max))

if n_step < 1:
  raise ValueError("n_step (%i) should be greater than 1 (it's third range param)" % (n_step))

print("epsilon_min=%f ; epsilon_max=%f ; epsilon_nb_samples=%i" % (epsilon_min, epsilon_max, epsilon_nb_samples))
print("n_min=%i ; n_max=%i ; n_step=%i\n" % (n_min, n_max, n_step))

time_now = datetime.now().isoformat()
# print(time_now)

directory = "results/"
filename = directory + "atk_results_" + time_now +  ".csv"
print(filename)
mode = "a" # append
with open(filename, mode) as file:
    str_to_append = "epsilon" + " ; " + "n" + " ; "
    str_to_append += "elapsed (sec)" + " ; " + "correct" + "\n"
    file.write(str_to_append)

p = 906451402757531491528347543991965234378604973129269705492472129523782487766614021889227442682267886074307292927204600169914974164281891819286851424239355717753220030403878552060160148901948842626145985604965725925995708353545622337042837155897328722293454170436280382414179204815920139165021038274214324133441128748041485323750264965207
# p = 141248963202789738385151576179393590973502764840921345284515324749658045406106556787307477676742793808588646507718277178459056848710287114028508966716034846416960817351271639403392870796875489677144462083463274919189144396641623516781747457999095000405375399455735643976723371459095368171647793931829914660385269774931451720954214829359651147687970129127084331090910468808513499199454609291257126147675699908283568543200260537675427822100983209236528863499044776900859774409034607530378348944475053530997857737795368784386246537972282244947636782183800965697986476293425685086042232999599541142234972082935379218724174464009785947694341690217532954581
q = 1059913563491035635396448336427206671662765775323
# q = 904625697166532776746648321658956727124622014958963470375753145287631998221
Zp = GF(p)
Zq = GF(q)
g = 293371185853534367511844757434644570812647513218435580316069229785172955124429736895770945422242233686785606862787032030077878386643174691259013000164799577907874573865328598727158515510280793452269117630500180299498233510391795063046406707109176370083243422230003054010329258322170583298853051287181677571803798228224133321144496297461
# g = 99483807066539319269845988771691295065570113480024680727385721323099683471930476239443787754174485627996487109429397776807394410332798135607364192305966931240017456516323664072562601670091665843862907459473139800086937089805140190820181732466594066911981601761352417857294020338927242538548476740451877750344037068909978459940778878158771369417195856348220817534566780989178981331964758943707233986437894472724134114687760943505174676772822073004591996046229212041695553003763507340759642510881660766203736537624606516165749601101354621714832310824253906416533583786079601643440805616978353542324617661368451485948918870766191022554947303745130041383
g = Zp(g)
x = Zq(1234567890987654321)
# x = Zq(689497418049590154556390310820821629110464212604956476070008078448262394083)
h = g ** x
index = 0 # index de la clé éphémère testée

#warm up (otherwise first mesure is longer)
test_epsilon = 0.9
test_n = 40
elapsed, correct = timed_attack(test_epsilon, test_n, Zq, g, x, 'LLL')

# np.linspace third param is the number of points in interval
for epsilon_frac in np.linspace(epsilon_min, epsilon_max, epsilon_nb_samples):
  with open(filename, mode) as file:
    for n in range(n_min, n_max, n_step):
      epsilon = f"{epsilon_frac:.3f}"
      # print(epsilon, n)
      elapsed, correct = timed_attack(float(epsilon), n, Zq, g, x)
      str_to_append = str(epsilon) + " ; " + str(n) + " ; "
      str_to_append += str(elapsed) + " ; " + str(correct) + "\n"
      file.write(str_to_append)