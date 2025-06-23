using JLD2

# exp_num_list = collect(1:20160) .- 1
exp_num_list = collect(0:14400)

x = 0
result_dict = Dict()
for exp_index in exp_num_list

    if !isfile("/home/francois-lamothe/Desktop/shapley_approximation/results/results_$(exp_index).jld2")
        global x += 1
        continue
    end


    # # dataset_list = ["random_sparse", "random", "monotone_sparse", "monotone", "voting", "airport", "knapsack"]
    # dataset_list = ["varying_sparseness", "varying_variance_tradeoff", "voting", "airport", "knapsack"]
    # algorithm_list = ["kernel", "mc no stratif", "mc position stratif", "mc player stratif", "mc both stratif", "cc position stratif", "cc both stratif", "cc position stratif neyman", "mc position stratif neyman"]
    # nb_instances = 80
    # sample_multiplier_list = [1, 4, 20, 100]
    # # sample_multiplier_list = [300, 1000]
    # arg= arg_init
    # instance_index, arg = arg % nb_instances + 1, arg÷nb_instances
    # sample_multiplier_index, arg = arg % length(sample_multiplier_list) + 1, arg÷length(sample_multiplier_list)
    # algorithm_index, dataset_index = arg % length(algorithm_list) + 1, arg÷length(algorithm_list) + 1
    # algorithm_name, dataset_name = algorithm_list[algorithm_index], dataset_list[dataset_index]
    # sample_multiplier = sample_multiplier_list[sample_multiplier_index]


    if exp_index == 9 continue end
    algorithm_name, dataset_name, nb_players, instance_index, nb_samples, efficicency = load_object("/home/francois-lamothe/Desktop/shapley_approximation/results/results_$(exp_index).jld2")
    
    if !haskey(result_dict, algorithm_name) result_dict[algorithm_name] = Dict() end
    if !haskey(result_dict[algorithm_name], dataset_name) result_dict[algorithm_name][dataset_name] = Dict() end
    if !haskey(result_dict[algorithm_name][dataset_name], nb_players) result_dict[algorithm_name][dataset_name][nb_players] = Dict() end
    if !haskey(result_dict[algorithm_name][dataset_name][nb_players], nb_samples) result_dict[algorithm_name][dataset_name][nb_players][nb_samples] = Float64[] end
    push!(result_dict[algorithm_name][dataset_name][nb_players][nb_samples], efficicency)
end
println(x)

using Dates
save_object("/home/francois-lamothe/Desktop/shapley_approximation/processed_results/exp_pfcalcul_$(now()).jld2", result_dict)
