# ---
# title: Entre les poteaux, la biodiversité
# repository: tpoisot/BIO245-modele
# auteurs:
#    - nom: Farah-Lajoie
#      prenom: Mathis
#      matricule: 20280102
#      github: MathisFarah
#    - nom: Fournier
#      prenom: Rosanne
#      matricule: 20332066
#      github: rosannefournier
# ---

# # Introduction

# Dans cette simulation, un corridor sous une lignée électrique à haute tension est aménagé. Celui-ci est 
# établit tout en respectant des consignes, pour garantir la biodiversité et les réglements de sécurité de 
# l'infrasctructure avec une deuxième espèce de buisson, un rosier. Ce buisson est le choix parfait, car il 
# est important pour favoriser la connectivité écologique avec sa floraison, l'attraction de pollinisateur 
# et la petite faune qu'il apportera. De plus, il possède une grandeur qui ne sera pas néfaste pour les
# lignes électriques @HydroQuebec2025.

# # Présentation du modèle

# Pour modéliser cette dynamique, on utilise la chaine de Markov. C'est un modèle de transitions par états,
# où chaque passerelle peut évoluer à différents états ; vide, herbe, pivoine ou rosier. Les parcelles transitent 
# d'un état à un autre selon une matrice de probabilités. Le modèle peut être appliqué de manière déterministe 
# avec des valeurs théoriques continues et de manière stochastique avec des nombres entiers, rendant le tout plus 
# réaliste. La chaine de Markov est un processus sans mémoire, l'état futur de la parcelle dépend seulement de son
# état actuel @Balzter2000.

# # Implémentation

# On simule le nouveau corridor de 200 parcelles vides, dont jusqu'à 50 de celles-ci peuvent êtres plantées 
# avec les deux sortes de buisson (pivoine et rosier). L'objectif est que dans 80% des simulations, 
# il doit avoir 20% des parcelles végétalisées (30% des herbes et 70% des buissons, dont au moins 30% de l'espèce 
# minoritaire). Quelle doit être la population initiale et quelle sera la matrice de transition pour respecter cet 
# objectif? Il doit y avoir un mélange équilibré entre les deux espèces de buissons à des probabilités de transitions 
# favorables pour leur permettre de coexister.

# # Code pour le modèle
# ## Packages nécessaires

# Initialisation du générateur de nombres aléatoires

import Random
Random.seed!(2045)

# Bibliothèque de visualisation graphique

import CairoMakie
using CairoMakie

# Bibliothèque de distribution statistique

import Distributions
using Distributions

# ## Vérification de la matrice de transition

"""
check_transition_matrix!(T)

Permet de s'assurer que chaque ligne de la matrice a une somme de 1. Sinon, un message d'erreur apparait dans le terminal

T est la matrice de transition
"""
function check_transition_matrix!(T)                                                        ## Le "!" permet de modifier la matrice de la fonction en mémoire
    for ligne in axes(T, 1)
        if sum(T[ligne, :]) != 1
            @warn "La somme de la ligne $(ligne) n'est pas égale à 1 et a été modifiée"
            T[ligne, :] ./= sum(T[ligne, :])
        end
    end
    return T
end

# ## Vérification des arguments
# Programmation défensive : valide les contraintes des arguments et renvoie un message d'erreur si non
"""
check_function_arguments(transitions, states)

Valide la cohérence des arguments. Vérifie que la matrice est carrée, que le nombre d'états correspond et qu'aucune probabilité de transition n'est négative.

'transitions' est la matrice de transition
'states' est le vecteur d'état initial 
"""
function check_function_arguments(transitions, states)
    if size(transitions, 1) != size(transitions, 2)
        throw("La matrice de transition n'est pas carrée")
    end

    if size(transitions, 1) != length(states)
        throw("Le nombre d'états ne correspond pas à la matrice de transition")
    end
    for lignes in axes(transitions, 1)
        for colonnes in axes(transitions, 2)
            if transitions[lignes, colonnes] < 0
                throw("La valeur de transition à la position $(lignes) $(colonnes) est inférieur a 0")
            end
        end
    end
    return nothing                     ## Ne retourne rien si tout est valide
end

# ## Simulation stochastique

"""
_sim_stochastic!(timeseries, transitions, generation)

Pour chaque état et générations, la fonction tire aléatoirement le nombre de parcelles qui transitent d'un état à un autre avec une distribution multinomiale.

'timeseries' est la matrice des états x générations
'transitions' est la matrice de transition 
'generation' est le nombre de génération
"""
function _sim_stochastic!(timeseries, transitions, generation)
    for state in axes(timeseries, 1)
        pop_change = rand(Multinomial(timeseries[state, generation], transitions[state, :]))
        timeseries[:, generation+1] .+= pop_change
    end
end

# ## Simulation déterministe

"""
_sim_determ!(timeseries, transitions, generation)

Multiplie le vecteur d'état actuel par la matrice de transition.

'timeseries' est la matrice des états x générations
'transitions' est la matrice de transition 
'generation' est le nombre de génération
"""
function _sim_determ!(timeseries, transitions, generation)
    pop_change = (timeseries[:, generation]' * transitions)'
    timeseries[:, generation+1] .= pop_change

end

# ## Simulation

"""
simulation(transitions, states; generations=500, stochastic=false)

Effectue la simulation sur un nombre défini de générations (ici 500 par défaut). Initialise la série temporelle et sélectionne le mode stochastique ou déterministe.

'transitions' est la matrice de transition 
'states' est le vecteur d'état initial 
'generation' est le nombre de génération
'stochastic' si true utilise la simulation stochastique, mais par défaut est false donc déterministe
"""
function simulation(transitions, states; generations=500, stochastic=false)

    check_transition_matrix!(transitions)
    check_function_arguments(transitions, states)

    _data_type = stochastic ? Int64 : Float32                           ## Selon le type de données, choisi si renvoie stochastique (entier) ou déterministe (décimaux)
    timeseries = zeros(_data_type, length(states), generations + 1)     ## Créer une matrice vide pour stocker les résultats
    timeseries[:, 1] = states                                           ## Initialise la première colonne avec l'état initial

    ## Sélectionne la fonction de la simulation selon le mode

    _sim_function! = stochastic ? _sim_stochastic! : _sim_determ!

    ## Boucle pour le faire sur plusieurs générations

    for generation in Base.OneTo(generations)
        _sim_function!(timeseries, transitions, generation)
    end

    return timeseries
end

# ## États
# Vide, Herbe, Pivoine, Rosier
s = [150, 40, 10, 0]         ## Vecteur initial
states = length(s)           ## Nombre d'états
patches = sum(s)             ## Nombre de parcelles

# ## Matrice de transition

T = zeros(Float32, states, states)
T[1, :] = [81, 5, 9, 5]               ## Probabilités depuis l'état vide
T[2, :] = [76, 20, 3, 1]              ## Probabilités depuis l'état herbe
T[3, :] = [78, 10, 9, 3]              ## Probabilités depuis l'état pivoine
T[4, :] = [83, 2, 6, 9]               ## Probabilités depuis l'état rosier

## Noms et couleurs des états pour la légende

states_names = ["Vide", "Herbe", "Pivoine", "Rosier"]
states_colors = [:grey40, :orange, :teal, :pink]

# ## Visualisation

f = Figure()
ax = Axis(f[1, 1], xlabel="Nb. générations", ylabel="Nb. parcelles")

# Simulation stochastique

## Définition des arguments

nb_sim = 2000
equilibre_vide = zeros(nb_sim)
equilibre_herbe = zeros(nb_sim)
equilibre_pivoine = zeros(nb_sim)
equilibre_rosier = zeros(nb_sim)

for i in 1:nb_sim
    sto_sim = simulation(T, s; stochastic=true, generations=50)

    ## Calcule le pourcentage des parcelles dans chaque état 

    equilibre_vide[i] = sto_sim[1, end] / patches * 100
    equilibre_herbe[i] = sto_sim[2, end] / patches * 100
    equilibre_pivoine[i] = sto_sim[3, end] / patches * 100
    equilibre_rosier[i] = sto_sim[4, end] / patches * 100

    for j in eachindex(s)
        lines!(ax, sto_sim[j, :], color=states_colors[j], alpha=0.01)
    end
end

# Simulation déterministe

det_sim = simulation(T, s; stochastic=false, generations=50)
for i in eachindex(s)
    lines!(ax, det_sim[i, :], color=states_colors[i], alpha=1, label=states_names[i], linewidth=2)
end

## Paramètres pour le graphique : légende et limite des axes 

axislegend(ax)
tightlimits!(ax)

# # Présentation des résultats

f

# Figure 1 : Nombres de parcelles dans chacun des états à travers les générations 

# À l'aide de la simulation déterministe, il est osbervable que chacun des états atteint son équilibre très rapidement, soit après moins
# de 5 générations. Les nombreuses simulations stochastique semblent suivrent la simulation déterministe.

h = Figure()
hist(h[1, 1], equilibre_vide, color=:grey40, axis=(title="Équilibre Vide", xlabel="Parcelles (%)", ylabel="Fréquence"))
hist(h[1, 2], equilibre_herbe, color=:orange, axis=(title="Équilibre Herbe", xlabel="Parcelles (%)", ylabel="Fréquence"))
hist(h[2, 1], equilibre_pivoine, color=:teal, axis=(title="Équilibre Pivoine", xlabel="Parcelles (%)", ylabel="Fréquence"))
hist(h[2, 2], equilibre_rosier, color=:pink, axis=(title="Équilibre Rosier", xlabel="Parcelles (%)", ylabel="Fréquence"))
h

# Figure 2 : Histogrammes des fréquences des états possibles des parcelles selon leur pourcentage d'occupation pour 2000 simulations stochastiques (en équilibre) 

# À l'aide de ces 4 figures il est possible d'estimer quel pourcentage des parcelles est occupé par quel état est à la fin des simulations.
# Il y a environ 81% des parcelles qui sont vides à l'équilibre, donc 19% qui sont végétalisées. Parmis cela, 6% qui sont couvertes d'herbes,
# environ 8% qui sont couvertes de pivoines et 5% des parcelles qui sont des rosiers.

# # Discussion

# La population initiale choisi parmi les 200 parcelles contenait 150 parcelles vides, 40 d'herbes, 10 de pivoines et aucun rosiers. 
# La matrice de transition contient ces valeurs :
# [81,  5, 9, 5]
# [76, 20, 3, 1]
# [78, 10, 9, 3]
# [83,  2, 6, 9] 
# . Comme la matrice de transition contient des valeurs qui garantissent très fortement les équilibres voulus, soit 80% vides, 6% herbes,
# et au minimum 4,2% du buisson le moins abondant, la population intiale n'a peu d'importance dans l'atteinte des points d'équilibre désirés.
# En effet, les valeurs de transitions ont été séléctionnées pour que chaque état dans lequel une parcelle se trouve, les probabilités 
# de transitionner vers un autre état sont fortement liées aux équilibres désirés. Cela explique pourquoi la simluation déterministe se
# stabilise très rapidement soit vers 5 générations et aussi pourquoi les simulations stochastiques suivent de très près la simluation 
# détmerministe. Malgré le fait que les valeurs dans la matrice de transitions assurent l'atteinte des pourcentage attendues dans la 
# majorité des cas, cela reflète peu une situation biologique réelle. En effet, le stade d'une plante est souvent plus linéaire, c'est à 
# dire qu'une parcelle vide à beaucoup plus de chance rester vide ou bien de devenir un herbe à la prochaine génération et non de passer
# à un stade de buisson directement. L'herbe, quant à elle, a plus de chance de rester de l'herbe, de redevenir vide, ou même de passer au premier
# stade de buisson que de passer direcetemnt au deuxième stade de buisson. Alors que les valeurs de transitions séléctionnées assurent quasiment 
# toujours les pourcentages désirés, elles ne reflètent pas du tout une situation réelle.
