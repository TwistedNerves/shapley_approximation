#using Random, Distributions, Combinatorics, JLD2
using Random
using Distributions
using Combinatorics
using JLD2

include("./instance_generation.jl")
include("./shapley_algorithms.jl")


function average_normalized_error2(target::Vector{Float64}, x::Vector{Float64}, epsilon::Float64=10^-1)::Float64
    size = length(target)
    mean = 0.
    for i in 1:size
        if target[i] != 0. mean += abs.(target[i] .- x[i])./abs.(target[i]) end
    end
    return mean / size
end

function average_normalized_error(target::Vector{Float64}, x::Vector{Float64}, epsilon::Float64=10^-1)::Float64
    size = length(target)
    normalized_error = abs.(target .- x)./max.(abs.(target), epsilon)
    return sum(normalized_error) / size
end

global_path = "/pfcalcul/work/flamothe"
#global_path = "/home/francois/Desktop/"

arg_init = parse(Int64, ARGS[1]) - 1

if arg_init < 50000
    dataset_list = ["random_sparse", "random", "monotone_sparse", "monotone", "voting", "airport", "knapsack"]
    algorithm_list = ["kernel", "mc no stratif", "mc position stratif", "mc player stratif", "mc both stratif", "cc position stratif", "cc both stratif", "cc position stratif neyman", "mc position stratif neyman"]
    nb_players_list = [10, 20, 50, 100]
    nb_instances_per_category = 20
    sample_multiplier_list = [1, 4, 20, 100]
    arg= arg_init
    instance_index, arg = arg % nb_instances_per_category + 1, arg÷nb_instances_per_category
    nb_players_index, arg = arg % length(nb_players_list) + 1, arg÷length(nb_players_list)
    sample_multiplier_index, arg = arg % length(sample_multiplier_list) + 1, arg÷length(sample_multiplier_list)
    algorithm_index, dataset_index = arg % length(algorithm_list) + 1, arg÷length(algorithm_list) + 1
    algorithm_name, dataset_name = algorithm_list[algorithm_index], dataset_list[dataset_index]
    sample_multiplier, nb_players = sample_multiplier_list[sample_multiplier_index], nb_players_list[nb_players_index]
else
    dataset_list = ["random_sparse", "random", "monotone_sparse", "monotone", "voting", "airport", "knapsack"]
    algorithm_list = ["mc position stratif", "mc position stratif neyman", "cc position stratif", "cc position stratif neyman"]
    nb_players_list = [10, 20, 50, 100]
    nb_instances_per_category = 20
    sample_multiplier_list = [300, 1000]
    arg= arg_init - 50000
    instance_index, arg = arg % nb_instances_per_category + 1, arg÷nb_instances_per_category
    nb_players_index, arg = arg % length(nb_players_list) + 1, arg÷length(nb_players_list)
    sample_multiplier_index, arg = arg % length(sample_multiplier_list) + 1, arg÷length(sample_multiplier_list)
    algorithm_index, dataset_index = arg % length(algorithm_list) + 1, arg÷length(algorithm_list) + 1
    algorithm_name, dataset_name = algorithm_list[algorithm_index], dataset_list[dataset_index]
    sample_multiplier, nb_players = sample_multiplier_list[sample_multiplier_index], nb_players_list[nb_players_index]
end

file_path = "$(global_path)/shapley_approximation/datasets/$(dataset_name)/$(dataset_name)_$(nb_players)_$(instance_index)"
evaluation_function, shapley_evaluator = read_symetric_sum_instance(file_path)

true_shap = shapley_evaluator()

nb_samples = sample_multiplier * nb_players * nb_players

if algorithm_name == "kernel" result = kernel_shapley_values(evaluation_function, nb_players, nb_samples) end
if algorithm_name == "mc no stratif" result = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples, player_stratification=false, position_stratification=false) end
if algorithm_name == "mc position stratif" result = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples, player_stratification=false) end
if algorithm_name == "mc player stratif" result = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples, position_stratification=false) end
if algorithm_name == "mc both stratif" result = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples) end
if algorithm_name == "cc position stratif" result = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples, contribution="complementary", player_stratification=false) end
if algorithm_name == "cc both stratif" result = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples, contribution="complementary") end
if algorithm_name == "cc position stratif neyman" result = complementary_contribution_neyman_allocation_shapley_values(evaluation_function, nb_players, nb_samples) end
if algorithm_name == "mc position stratif neyman" result = stratified_position_sampling_castro_values(evaluation_function, nb_players, nb_samples) end

efficicency = average_normalized_error(true_shap, result)
save_file_path = "$(global_path)/shapley_approximation/results/results_$(arg_init).jld2"
save_object(save_file_path, (algorithm_name, dataset_name, nb_players, instance_index, nb_samples, efficicency))
