using JLD2

nb_instances = 20
# exp_num_list = collect(1:20160) .- 1
exp_num_list = collect(0:60000)

x = 0
result_dict = Dict()
for exp_index in exp_num_list

    if !isfile("/home/francois/Desktop/shapley_approximation/results/results_$(exp_index).jld2")
        global x += 1
        continue
    end

    if exp_index < 50000
        arg = exp_index
        dataset_list = ["random_sparse", "random", "monotone_sparse", "monotone", "voting", "airport", "knapsack"]
        algorithm_list = ["kernel", "mc no stratif", "mc position stratif", "mc player stratif", "mc both stratif", "cc position stratif", "cc both stratif", "cc position stratif neyman", "mc position stratif neyman"]
        nb_players_list = [10, 20, 50, 100]
        nb_instances_per_category = 20
        sample_multiplier_list = [1, 4, 20, 100]
        instance_index, arg = arg % nb_instances_per_category + 1, arg÷nb_instances_per_category
        nb_players_index, arg = arg % length(nb_players_list) + 1, arg÷length(nb_players_list)
        sample_multiplier_index, arg = arg % length(sample_multiplier_list) + 1, arg÷length(sample_multiplier_list)
        algorithm_index, dataset_index = arg % length(algorithm_list) + 1, arg÷length(algorithm_list) + 1
        algorithm_name, dataset_name = algorithm_list[algorithm_index], dataset_list[dataset_index]
        sample_multiplier, nb_players = sample_multiplier_list[sample_multiplier_index], nb_players_list[nb_players_index]

    else
        arg = exp_index - 50000
        dataset_list = ["random_sparse", "random", "monotone_sparse", "monotone", "voting", "airport", "knapsack"]
        algorithm_list = ["mc position stratif", "mc position stratif neyman", "mc position stratif", "cc position stratif neyman"]
        nb_players_list = [10, 20, 50, 100]
        nb_instances_per_category = 20
        sample_multiplier_list = [300, 1000]
        instance_index, arg = arg % nb_instances_per_category + 1, arg÷nb_instances_per_category
        nb_players_index, arg = arg % length(nb_players_list) + 1, arg÷length(nb_players_list)
        sample_multiplier_index, arg = arg % length(sample_multiplier_list) + 1, arg÷length(sample_multiplier_list)
        algorithm_index, dataset_index = arg % length(algorithm_list) + 1, arg÷length(algorithm_list) + 1
        algorithm_name, dataset_name = algorithm_list[algorithm_index], dataset_list[dataset_index]
        sample_multiplier, nb_players = sample_multiplier_list[sample_multiplier_index], nb_players_list[nb_players_index]
    end

    algorithm_name, dataset_name, nb_players, instance_index, nb_samples, efficicency = load_object("/home/francois/Desktop/shapley_approximation/results/results_$(exp_index).jld2")
    
    if !haskey(result_dict, algorithm_name) result_dict[algorithm_name] = Dict() end
    if !haskey(result_dict[algorithm_name], dataset_name) result_dict[algorithm_name][dataset_name] = Dict() end
    if !haskey(result_dict[algorithm_name][dataset_name], nb_players) result_dict[algorithm_name][dataset_name][nb_players] = Dict() end
    if !haskey(result_dict[algorithm_name][dataset_name][nb_players], nb_samples) result_dict[algorithm_name][dataset_name][nb_players][nb_samples] = Float64[] end
    push!(result_dict[algorithm_name][dataset_name][nb_players][nb_samples], efficicency)
end
println(x)

using Dates
save_object("/home/francois/Desktop/shapley_approximation/processed_results/exp_pfcalcul_$(now()).jld2", result_dict)
