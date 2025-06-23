using Random, Distributions, Combinatorics, JLD2

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

function average_error(target::Vector{Float64}, x::Vector{Float64}, epsilon::Float64=10^-1)::Float64
    size = length(target)
    normalized_error = abs.(target .- x)
    return sum(normalized_error) / size
end

function average_squarred_normalized_error(target::Vector{Float64}, x::Vector{Float64}, epsilon::Float64=10^-1)::Float64
    size = length(target)
    normalized_error = abs.(target .- x)./max.(abs.(target), epsilon)
    return sum(normalized_error.^2) / size
end

# path = "/home/francois-lamothe/Desktop/shapley_approximation/datasets/"
# # dataset_name = "varying_sparseness"
# dataset_name = "varying_variance_tradeoff"

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


x = Float64[]
y = Float64[]
w = Float64[]
z = Float64[]
n = 30
for i in 1:n

    nb_players = 100
    nb_symetric_games = 5*nb_players
    # # create_game_values = create_subaditive_function
    create_game_values = create_monotone_function
    # # create_game_values = create_concave_function
    # # create_game_values = create_concave_function2
    # create_game_values = create_random_function
    # # create_game_values = create_knapsack_function
    # nb_symetric_games = 1
    # create_game_values = create_voting_function
    evaluation_function, shapley_evaluator = generate_symetric_sum_instance(nb_players, nb_symetric_games, create_game_values, "", 1.)
    
    # game_values_creation_info = [(() -> constant_distrib(2), create_monotone_function, 0.), (() -> exp_uniform_distrib(nb_players), create_monotone_function, 1.)]
    # evaluation_function, shapley_evaluator = generate_symetric_sum_instance(nb_players, nb_symetric_games, game_values_creation_info, "", 4.)
    

    function instance_name_from_index(index::Int64, path::String)::String
        list_files = readdir(path)
        sort!(list_files)
        return list_files[index]
    end
    global_path = "/home/francois-lamothe/Desktop"
    # dataset_name = "varying_variance_tradeoff"
    dataset_name = "varying_sparseness"
    dir_path = "$(global_path)/shapley_approximation/datasets/$(dataset_name)"
    instance_name = instance_name_from_index(i, dir_path)
    println(instance_name)

    file_path = "$(dir_path)/$(instance_name)"
    evaluation_function, shapley_evaluator = read_symetric_sum_instance(file_path)

    # nb_players = 50
    # evaluation_function, shapley_evaluator = generate_airport_instance(nb_players)
    # evaluation_function, shapley_evaluator = generate_airport_instance(nb_players, [1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,10,10,10,10,10,10,10,10,10,10])
    # evaluation_function, shapley_evaluator = generate_airport_instance(nb_players, [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9])

    # nb_players = 30
    # evaluation_function, shapley_evaluator = generate_spanning_tree_instance(nb_players)

    # println(compute_pre_shapley_table(evaluation_function, nb_players))

    shap = shapley_evaluator()
    # println(shap)

    nb_samples = 50 * nb_players * nb_players
    # nb_samples = 10 * nb_players + 1

    # kern_shap = kernel_shapley_values(evaluation_function, nb_players, nb_samples)
    # println("kern_shap : $(average_normalized_error(shap, kern_shap))")
    # push!(y, average_normalized_error(shap, kern_shap))

    no_stratif_shap = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples, position_stratification=false, player_stratification=false)
    println("no_stratif_shap : $(average_normalized_error(shap, no_stratif_shap))")
    push!(x, average_normalized_error(shap, no_stratif_shap))

    stratified_position_shap = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples, player_stratification=false)
    println("stratified_position_shap : $(average_normalized_error(shap, stratified_position_shap))")
    push!(y, average_normalized_error(shap, stratified_position_shap))

    player_stratif_values = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples, position_stratification=false, nb_max_chosen_possibilities=1)
    println("player_stratif_values : $(average_normalized_error(shap, player_stratif_values))")
    push!(z, average_normalized_error(shap, player_stratif_values))

    # player_stratif_values = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples, position_stratification=false, nb_max_chosen_possibilities=2)
    # println("player_stratif_values 2: $(average_normalized_error(shap, player_stratif_values))")
    # push!(w, average_normalized_error(shap, player_stratif_values))

    # position_player_stratif_values = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples, nb_max_chosen_possibilities=1, method="raking")
    # println("position_player_stratif_values : $(average_normalized_error(shap, position_player_stratif_values))")
    # println("position_player_stratif_values : $(average_error(shap, position_player_stratif_values))")
    # push!(x, average_normalized_error(shap, position_player_stratif_values))

    # position_player_stratif_values = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples, nb_max_chosen_possibilities=2, method="QP")
    # println("position_player_stratif_values 2: $(average_normalized_error(shap, position_player_stratif_values))")
    # push!(w, average_normalized_error(shap, position_player_stratif_values))


    # complementarity_contribution_sampling_shap = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples, contribution="complementary", player_stratification=false)
    # println("complementarity_contribution_sampling_shap : $(average_normalized_error(shap, complementarity_contribution_sampling_shap))")
    # println("complementarity_contribution_sampling_shap : $(average_error(shap, complementarity_contribution_sampling_shap))")
    # push!(y, average_normalized_error(shap, complementarity_contribution_sampling_shap))

    # complementary_contribution_neyman_allocation_shap = complementary_contribution_neyman_allocation_shapley_values(evaluation_function, nb_players, nb_samples)
    # println("complementary_contribution_neyman_allocation_shap : $(average_normalized_error(shap, complementary_contribution_neyman_allocation_shap))")
    # push!(y, average_normalized_error(shap, complementary_contribution_neyman_allocation_shap))

    # both_stratif_complementary_contribution_shap = post_stratif_indicator_values(evaluation_function, nb_players, nb_samples, contribution="complementary")
    # println("both_stratif_complementary_contribution_shap : $(average_normalized_error(shap, both_stratif_complementary_contribution_shap))")
    # push!(z, average_normalized_error(shap, both_stratif_complementary_contribution_shap))

    # stratified_position_sampling_castro = stratified_position_sampling_castro_values(evaluation_function, nb_players, nb_samples)
    # println("stratified_position_sampling_castro : $(average_normalized_error(shap, stratified_position_sampling_castro))")
    # println("stratified_position_sampling_castro : $(average_error(shap, stratified_position_sampling_castro))")
    # push!(z, average_normalized_error(shap, stratified_position_sampling_castro))

    println(i)
end

if length(x) > 0
    m = mean(x)
    std = sqrt(sum((x .- m).^2) / n)
    println("$m, $std")
end

if length(y) > 0
    m = mean(y)
    std = sqrt(sum((y .- m).^2) / n)
    println("$m, $std")
end

if length(z) > 0
    m = mean(z)
    std = sqrt(sum((z .- m).^2) / n)
    println("$m, $std")
end

if length(w) > 0
    m = mean(w)
    std = sqrt(sum((w .- m).^2) / n)
    println("$m, $std")
end
