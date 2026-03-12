# ---
# title: Titre du travail
# repository: tpoisot/BIO245-modele
# auteurs:
#    - nom: Farah-Lajoie
#      prenom: Mathis
#      matricule: XXXXXXXX
#      github: XXXXXX
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

# ## Packages nécessaires

import Random
Random.seed!(2045)

import CairoMakie
using CairoMakie

import Distributions
using Distributions
# ## Documentation des fonctions

"""
    foo(x, y)

Cette fonction ne fait rien.
"""
function foo(x, y)
    ## Cette ligne est un commentaire
    return nothing
end




function check_transition_matrix!(T)
    for ligne in axes(T, 1)
        if sum(T[ligne, :]) != 1
            @warn "La somme de la ligne $(ligne) n'est pas égale à 1 et a été modifiée"
            T[ligne, :] ./= sum(T[ligne, :])
        end
    end
    return T
end

function check_function_arguments(transitions, states)
    if size(transitions, 1) != size(transitions, 2)
        throw("La matrice de transition n'est pas carrée")
    end

    if size(transitions, 1) != length(states)
        throw("Le nombre d'états ne correspond psa à la matrice de transition")
    end
    return nothing
end

function _sim_stochastic!(timeseries, transitions, generation)
        for state in axes(timeseries, 1)
        pop_change = rand(Multinomial(timeseries[state, generation], transitions[state, :]))
        timeseries[:, generation+1] .+= pop_change
    end
end

function _sim_determ!(timeseries, transitions, generation)
        pop_change = (timeseries[:, generation]' * transitions)'
        timeseries[:, generation+1] .= pop_change

end
function simulation(transitions, states; generations=500, stochastic=false)
    
    check_transition_matrix!(transitions)
    check_function_arguments(transitions, states)

    _data_type = stochastic ? Int64 : Float32
    timeseries = zeros(_data_type, length(states), generations + 1)
    timeseries[:, 1] = states

    _sim_function! = stochastic ? _sim_stochastic! : _sim_determ!

    for generation in Base.OneTo(generations)
        _sim_function!(timeseries, transitions, generation)
    end

    return timeseries
end

# States
# Barren, Grass, Shrubs
s = [0, 500, 0]
states = length(s)
patches = sum(s)

# Transitions
T = zeros(Float64, states, states)
T[1, :] = [110, 8, 0]
T[2, :] = [2, 120, 3]
T[3, :] = [1, 0, 94]

states_names = ["Barren", "Grasses", "Shrubs"]
states_colors = [:grey40, :orange, :teal]

# Simulations

f = Figure()
ax = Axis(f[1, 1], xlabel="Nb. générations", ylabel="Nb. parcelles")

# Simulation stochastique
for _ in 1:10
    sto_sim = simulation(T, s; stochastic=true, generations=200)
    for i in eachindex(s)
        lines!(ax, sto_sim[i, :], color=states_colors[i], alpha=0.2)
    end
end

# Simulation déterministe
det_sim = simulation(T, s; stochastic=false, generations=200)
for i in eachindex(s)
    lines!(ax, det_sim[i, :], color=states_colors[i], alpha=1, label=states_names[i])
end

axislegend(ax)
tightlimits!(ax)
current_figure()

# # Présentation des résultats

# La figure suivante représente des valeurs aléatoires:

hist(randn(100))

# # Discussion

# On peut aussi citer des références dans le document `references.bib`,
# @ermentrout1993cellular -- la bibliographie sera ajoutée automatiquement à la
# fin du document.
