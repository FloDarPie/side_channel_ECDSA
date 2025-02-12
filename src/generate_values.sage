load("src/impl_99.sage")
from pathlib import Path


print("Indiquez le mode que vous souhaitez appliquer :\n1 - générer des couples p/q\n>", end='')
mode = input()
try:
    mode = int(mode)
except:
    print("Mode inconnu - fin")
    exit()


if mode == 1:
    print("Choississez le nombre de couples p/q souhaitez\n>", end='')
    number = input()
    try:
        number = int(number)
    except:
        print("Nombre inconnu - fin")
    print("Valeur de L : (defaut 1024)\n>", end='')
    l = input()
    try:
        l = int(l)
    except:
        print("Nombre inconnu - fin")
    print("Valeur de N : (defaut 160)\n>", end='')
    n = input()
    try:
        n = int(n)
    except:
        print("Nombre inconnu - fin")
    print("Ajouter au fichier (a)/ Réécrire le fichier (w)\n>", end='')
    option = input()
    if not (option=="w" or option=="a"):
        print("Entrée inconnue - fin")
        exit()

    filename = Path("./src/plots/p_q_keys/"+str(l)+"_"+str(n))
    
    with open(filename, option) as file:
        for i in range(number):
            p,q,_,_ = generate_p_q(l,n)
            file.write(f"{p}:{q}\n")
            progress = (i + 1) / number * 100
            print(f"\r>>>{float(progress):.2f}%", end='')
    print("\nLes clés ont été enregistrées dans 'p_q_keys' - fin")
else:
    print("Mode inconnu - fin")