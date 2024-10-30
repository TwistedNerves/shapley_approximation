include("./ShapleyApproximation.jl")
using .ShapleyApproximation



# Generate a cooperative game
nb_players = 20
nb_symetric_games = 5*nb_players
create_game_values = ShapleyApproximation.create_monotone_function
# create_game_values = ShapleyApproximation.create_knapsack_function
evaluation_function, _ = ShapleyApproximation.generate_symetric_sum_instance(nb_players, nb_symetric_games, create_game_values)



nb_samples = 100 * nb_players * nb_players



# Compute the Shapley value
shapley_value = ShapleyApproximation.post_stratif_indicator_values(evaluation_function, nb_players, nb_samples)

println(shapley_value)

