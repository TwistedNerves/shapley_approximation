using Random, Distributions, Combinatorics, JLD2

include("./instance_generation.jl")
include("./shapley_algorithms.jl")


path = "/home/francois-lamothe/Desktop/shapley_approximation/datasets/"
# dataset_name = "varying_sparseness"
# dataset_name = "varying_variance_tradeoff"
dataset_name = "weighted_graph"


# for proba in [0., 0.33, 0.66, 1.]
#     for repeat in 1:20
#         nb_players = 100
#         file_path = path*"/"*dataset_name*"/$(dataset_name)_$(nb_players)_$(proba)_$(repeat)"
#         nb_symetric_games = 5*nb_players
#         # game_values_creation_info = [(() -> constant_distrib(2), create_monotone_function, proba), (() -> exp_uniform_distrib(nb_players), create_monotone_function, 1 - proba)]
#         game_values_creation_info = [(() -> exp_uniform_distrib(nb_players), create_random_function, proba), (() -> exp_uniform_distrib(nb_players), create_monotone_function, 1 - proba)]
#         evaluation_function, shapley_evaluator = generate_symetric_sum_instance(nb_players, nb_symetric_games, game_values_creation_info, file_path, 4.)
#     end
# end

for nb_players in [10, 20, 50, 100]
    for repeat in 1:20
        file_path = path*"/"*dataset_name*"/$(dataset_name)_$(nb_players)_$(repeat)"
        nb_symetric_games = 5*nb_players
        game_values_creation_info = [(() -> constant_distrib(2), create_scaled_unanimity_function, 1.)]
        evaluation_function, shapley_evaluator = generate_symetric_sum_instance(nb_players, nb_symetric_games, game_values_creation_info, file_path)
    end
end
