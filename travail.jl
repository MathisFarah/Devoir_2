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
# lignes électriques.

# # Présentation du modèle

# Pour modéliser cette dynamique, on utilise la chaine de Markov. C'est un modèle de transitions par états,
# où chaque passerelle peut évoluer à différents états ; vide, herbe, pivoine ou rosier. Les parcelles transitent 
# d'un état à un autre selon une matrice de probabilités. Le modèle peut être appliqué de manière déterministe 
# avec des valeurs théoriques continues et de manière stochastique avec des nombres entiers, rendant le tout plus 
# réaliste. La chaine de Markov est un processus sans mémoire, l'état futur de la pacerelle dépend seulement de son
# état actuel.

# # Implémentation

# On simule le nouveau corridor de 200 parcelles vides, dont jusqu'à 50 de celles-ci peuvent êtres plantées 
# avec les deux sortes de buisson (pivoine et rosier). L'objectif est que dans 80% des simulations, 
# il doit avoir 20% des parcelles végétalisées (30% des herbes et 70% des buissons, dont au moins 30% de l'espèce 
# minoritaire). Quelle doit être la population initiale et quelle sera la matrice de transition pour respecter cet 
# objectif? Il doit y avoir une mélange équilibré entre les deux espèces de buissons à des probabilités de transitions 
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
# ## Documentation des fonctions

"""
    foo(x, y)

Cette fonction ne fait rien.
"""
function foo(x, y)
    return nothing
end

# ## Vérification de la matrice de transition
# S'assurer que chaque ligne de la matrice a une somme de 1. Sinon, un message d'erreur apparaitera dans le terminal
# Le "!" permet de modifier la matrice de la fonction en mémoire

function check_transition_matrix!(T)
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
                throw("La valeur de transition a la position $(lignes) $(colonnes) est inférieur a 0")
            end
        end
    end
    return nothing
end

# ## Simulation stochastique
# Pour chaque état, la fonction tire aléatoirement le nombre parcelles qui transitent d'un état 
# à un autre avec une distribution multinomiale.

function _sim_stochastic!(timeseries, transitions, generation)
        for state in axes(timeseries, 1)
        pop_change = rand(Multinomial(timeseries[state, generation], transitions[state, :]))
        timeseries[:, generation+1] .+= pop_change
    end
end

# ## Simulation déterministe
# Multiplie le vecteur d'état actuel par la matrice de transition

function _sim_determ!(timeseries, transitions, generation)
        pop_change = (timeseries[:, generation]' * transitions)'
        timeseries[:, generation+1] .= pop_change

end

# ## Simulation

function simulation(transitions, states; generations=500, stochastic=false)
    
    check_transition_matrix!(transitions)
    check_function_arguments(transitions, states)

    _data_type = stochastic ? Int64 : Float32                           # Selon le type de données, choisi renvoie si stochastic est vrai ou faux
    timeseries = zeros(_data_type, length(states), generations + 1)     # Créer une matrice vide pour stocker les résultats
    timeseries[:, 1] = states                                           # Initialise la première colonne avec l'état initial

# Séletionne la fonction de la simulation selon le mode

    _sim_function! = stochastic ? _sim_stochastic! : _sim_determ!

# Le faire sur plusieurs générations

    for generation in Base.OneTo(generations)
        _sim_function!(timeseries, transitions, generation)
    end

    return timeseries
end

# ## États
# Vide, Herbe, Pivoine, Rosiers
s = [150, 40, 10, 0]         # Vecteur initial
states = length(s)      # Nombre d'états
patches = sum(s)        # Nombre de parcelles

# ## Matrice de transition
T = zeros(Float32, states, states)
T[1, :] = [0.81, 0.05, 0.09, 0.05]               # Probabilités depuis l'état vide
T[2, :] = [0.76, 0.20, 0.03, 0.01]               # Probabilités depuis l'état herbe
T[3, :] = [0.78, 0.10, 0.10, 0.02]               # Probabilités depuis l'état pivoine
T[4, :] = [0.83, 0.02, 0.08, 0.07]               # Probabilités depuis l'état rosiers

# Noms et couleurs des états pour la légende

states_names = ["Vide", "Herbe", "Pivoine", "Rosiers"]
states_colors = [:grey40, :orange, :teal, :pink]

# ## Visualisation

f = Figure()
ax = Axis(f[1, 1], xlabel="Nb. générations", ylabel="Nb. parcelles")

# Simulation stochastique
nb_sim = 1000
equilibre_vide = zeros(nb_sim)
equilibre_herbe = zeros(nb_sim)
equilibre_pivoine = zeros(nb_sim)
equilibre_rosiers = zeros(nb_sim)

for i in 1:nb_sim
    sto_sim = simulation(T, s; stochastic=true, generations=100)

    equilibre_vide[i] = sto_sim[1, end]/patches
    equilibre_herbe[i] = sto_sim[2, end]/patches
    equilibre_pivoine[i] = sto_sim[3, end]/patches
    equilibre_rosiers[i] = sto_sim[4, end]/patches
    for j in eachindex(s)
        lines!(ax, sto_sim[j, :], color=states_colors[j], alpha=0.1)
    end
end

# Simulation déterministe

det_sim = simulation(T, s; stochastic=false, generations=100)
for i in eachindex(s)
    lines!(ax, det_sim[i, :], color=states_colors[i], alpha=1, label=states_names[i], linewidth=2)
end

# Paramètres pour le graphique : légende et limite des axes 

axislegend(ax)
tightlimits!(ax)
current_figure()

# # Présentation des résultats

# La figure suivante représente des valeurs aléatoires:
h = Figure()
hist(h[1, 1], equilibre_vide, color = :grey40)
hist(h[1, 2], equilibre_herbe, color = :orange)
hist(h[2, 1], equilibre_pivoine, color = :teal)
hist(h[2, 2], equilibre_rosiers, color = :pink)
h

# # Discussion
