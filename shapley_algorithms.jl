function mean_and_variance(value_list::Vector{Float64})::Tuple{Float64, Float64}
    mean = sum(value_list) / length(value_list)
    variance = sum((value_list .- mean).^2) / length(value_list)
    return mean, variance
end

function mean(value_list::Vector{Float64})::Float64
    mean = sum(value_list) / length(value_list)
    return mean
end

function variance(value_list::Vector{Float64})::Float64
    mean = sum(value_list) / length(value_list)
    variance = sum((value_list .- mean).^2) / length(value_list)
    return variance
end





function post_stratif_indicator_values(evaluation_function::Function, nb_players::Int64, evaluation_budget::Int64;
                                min_size::Int64=-1, method::String="raking", position_stratification::Bool=true, contribution::String="marginal",
                                player_stratification::Bool=true, normalization_coefficient::Float64=0.01, nb_max_chosen_possibilities::Int64=1)::Vector{Float64}
    # This function implements most of the approximation method of this package. They all rely on sampling. Setting the parameters enable to switch between the different methods
    # evaluation_function::Function -> function which takes a subset of player and returns its cost. Defines the game whose shapley value is computed.
    # nb_players::Int64 -> number of player of the game
    # evaluation_budget::Int64 -> number of authorized evaluations of the value function
    # contribution::String="marginal" -> the type of contribution being sampled, marginal or complmentary
    # position_stratification::Bool=true -> decides whether or not to apply stratification according to player position (i.e. subset size)
    # player_stratification::Bool=true -> decides whether or not to apply stratification according to the presence of other players
    # method::String="raking" -> method used to compute the weights of the average after stratification : raking, barycenter or QP 
    # min_size::Int64=-1 -> minimum size of a set of samples after subdivision for the stratification (used for player_stratification=True only) default is nb_players
    # normalization_coefficient::Float64=0.01 : used only for the method QP, ensure that the computed matrix is invertible
    
    sampled_values = [Tuple{Vector{Bool}, Float64, Int64}[] for player in 1:nb_players] # contains the samples used to estimate the shapley value
    if min_size == -1 min_size = nb_players end # setting the default value for nb_players
    shapley_values = zeros(nb_players) # returned values

    # Sampling of the marginal contributions : using the permutations to sample
    if contribution =="marginal"
        nb_iterations = floor(Int64, evaluation_budget / nb_players)
        for iteration_index in 1:nb_iterations
            permutation = shuffle(collect(1:nb_players))
            subset = Int64[]
            old_subset_eval = 0
            for player in permutation
                push!(subset, player)
                subset_eval = evaluation_function(subset)
                vector_subset = zeros(Bool, nb_players)
                vector_subset[subset] .= true
                push!(sampled_values[player], (vector_subset, subset_eval - old_subset_eval, length(sampled_values[player])+1))
                old_subset_eval = subset_eval
            end
        end
    
    # Sampling of the complementary contributions
    elseif contribution =="complementary"
        nb_iterations = floor(Int64, evaluation_budget / 2)
        for iter_index in 1:nb_iterations
            permutation = shuffle(1:nb_players)
            subset_size = rand(1:nb_players)
            subset = permutation[1:subset_size]
            complement_subset = permutation[subset_size+1:end]
            complementarity_contribution = evaluation_function(subset) - evaluation_function(complement_subset) 
            vector_subset = zeros(Bool, nb_players)
            vector_subset[subset] .= true
            for player in subset
                push!(sampled_values[player], (vector_subset, complementarity_contribution, length(sampled_values[player])+1))
            end
            vector_subset = zeros(Bool, nb_players)
            vector_subset[complement_subset] .= true
            for player in complement_subset
                push!(sampled_values[player], (vector_subset, -complementarity_contribution, length(sampled_values[player])+1))
            end
        end
    end

    # computing stratification events independently for each players 
    for (player, full_sample_list) in enumerate(sampled_values)
        print("$player  \r")
        nb_samples = length(full_sample_list)
        stratification_list = Tuple{Vector{Int64}, Float64}[]

        # computing according to which other player to stratify
        if player_stratification
            to_be_checked = [(1., 0, 0, full_sample_list)]
            while length(to_be_checked) != 0
                coefficient, nb_with, nb_without, sample_list = popfirst!(to_be_checked)
                proba_with = (nb_with + 1) / (nb_with + nb_without + 2)
                proba_without = (nb_without + 1) / (nb_with + nb_without + 2)
                possibility_list = []
                for other_player in shuffle(1:nb_players)
                    index_list_with = [sample_index for (vector_subset, subset_eval, sample_index) in sample_list if vector_subset[other_player]]
                    index_list_without = [sample_index for (vector_subset, subset_eval, sample_index) in sample_list if !vector_subset[other_player]]
                    if length(index_list_with) < min_size || length(index_list_without) < min_size continue end # controls that each event corresponds to a minimum number of samples
                    #the next lines compute the bias that can be removed if the stratification corresponding to other_player is done. The other_player with the largest removed bias is selected.
                    with, without = full_sample_list[index_list_with], full_sample_list[index_list_without]
                    mean_with, variance_with = mean_and_variance([subset_eval for (vector_subset, subset_eval, sample_index) in with])
                    mean_without, variance_without = mean_and_variance([subset_eval for (vector_subset, subset_eval, sample_index) in without])
                    empirical_mean = (length(with) * mean_with + length(without) * mean_without) / length(sample_list)
                    theoretical_mean = proba_with * mean_with + proba_without * mean_without
                    bias_squarred = (empirical_mean - theoretical_mean)^2
                    push!(possibility_list, (bias_squarred, with, without))
                end
                if length(possibility_list) <= 0 # if we cannot split the event anymore without having too few samples remaining : we use the current in the stratification
                    index_list = [sample_index for (subset, subset_eval, sample_index) in sample_list]
                    push!(stratification_list, (index_list, coefficient))
                else # selection of the nb_chosen_possibilities splittings that remove the most bias
                    sort!(possibility_list, rev=true)
                    nb_chosen_possibilities = min(length(possibility_list), nb_max_chosen_possibilities)
                    for (bias_squarred, with, without) in possibility_list[1:nb_chosen_possibilities]
                        push!(to_be_checked, (coefficient * proba_with, nb_with + 1, nb_without, with))
                        push!(to_be_checked, (coefficient * proba_without, nb_with, nb_without + 1, without))
                    end
                end
            end
        end

        # stratification according to player position in the permuation (equivalently according to subset size)
        if position_stratification
            for subset_size in 1:nb_players
                index_list = [sample_index for (vector_subset, eval, sample_index) in full_sample_list if sum(vector_subset) == subset_size]
                if length(index_list) > 0 
                    push!(stratification_list, (index_list, 1 / nb_players))
                end
            end
        end

        coefficient_list = ones(nb_samples) ./ nb_samples # contains the coefficient of each samples in the final estimates : these coefficient are the results of the stratification process

        # computing the coefficients using different methods
        if method == "raking"
            nb_raking_rounds = 100
            for index in 1:nb_raking_rounds
                for (index_list, coefficient) in stratification_list
                    sum_coefficients = sum(coefficient_list[index_list])
                    coefficient_list[index_list] .*= coefficient / sum_coefficients
                end
            end

        elseif method == "barycenter"
            nb_raking_rounds = 100
            for index in 1:nb_raking_rounds
                barycenter = zeros(nb_samples)
                for (index_list, coefficient) in stratification_list
                    sum_coefficients = sum(coefficient_list[index_list])
                    barycenter += coefficient_list
                    barycenter[index_list] += (coefficient / sum_coefficients - 1) * coefficient_list[index_list]
                end
                coefficient_list = barycenter ./ length(stratification_list)
            end
        elseif method == "QP"
            A = zeros(nb_samples, nb_samples)
            for sample_index in 1:nb_samples
                A[sample_index, sample_index] = normalization_coefficient
            end
            b = ones(nb_samples) * normalization_coefficient / nb_samples

            for (index_list, coefficient) in stratification_list
                vector = zeros(nb_samples)
                vector[index_list] .= 1.
                A += vector * vector'
                b += coefficient .* vector
            end

            coefficient_list = inv(A)*b
        else
            @assert false, "method not implemented"
        end
 
        # computing the shapley value using the samples and the computed coeeficients
        shapley_values[player] = sum([full_sample_list[sample_index][2] * coefficient_list[sample_index] for sample_index in 1:nb_samples]) / sum(coefficient_list)
    end

    return vec(shapley_values)
end




function stratified_position_sampling_castro_values(evaluation_function::Function, nb_players::Int64, nb_evaluations::Int64, min_nb_init_samples::Int64=10)::Vector{Float64}
    # Implements a method for approximating the shapley value. It uses sampling of marginal contributions with stratification according to player position.
    # Moreover, the process of sample allocation presented by Castro et. al. (https://doi.org/10.1016/j.cor.2017.01.019) is used 

    player_set = collect(1:nb_players)
    sampled_values = [[Float64[] for subset_size in 1:nb_players] for player in 1:nb_players] # contains the samples used to estimate the shapley value
    nb_samples = floor(Int64, nb_evaluations / 2)
    mean_nb_samples_per_size = div(nb_samples, nb_players * nb_players)

    if mean_nb_samples_per_size < 1 # if the sample budget is to low to benefit from sample allocation we revert to no sample allocation
        return post_stratif_indicator_values(evaluation_function, nb_players, nb_evaluations, player_stratification=false)
    end
    
    # Initial sampling in order to compute the target proportion of samples for each size
    initial_nb_sample_per_size = min(max(min_nb_init_samples, floor(Int64, mean_nb_samples_per_size / 2)), mean_nb_samples_per_size)
    println("$nb_evaluations, $nb_samples, $mean_nb_samples_per_size, $initial_nb_sample_per_size")
    for player in 1:nb_players
        other_players = filter(x -> x != player, player_set)
        for subset_size in 1:nb_players
            for sample_index in 1:initial_nb_sample_per_size
                subset = shuffle(other_players)[1:subset_size-1]
                subset_eval = evaluation_function(subset)
                push!(subset, player)
                subset_eval_with_player = evaluation_function(subset)
                push!(sampled_values[player][subset_size], subset_eval_with_player - subset_eval)
            end
        end
    end

    # Computing the remaining samples to allocate
    remaining_samples_per_size = []
    for player in 1:nb_players
        target_proportions = [length(sampled_values[player][subset_size]) > 0 ? sqrt(variance(sampled_values[player][subset_size])) : 0 for subset_size in 1:nb_players]
        if sum(target_proportions) == 0 
            push!(remaining_samples_per_size, zeros(Int64, nb_players))
        else
            push!(remaining_samples_per_size, allocate_remaining_samples(target_proportions, ones(Int64, nb_players) * initial_nb_sample_per_size, floor(Int64, nb_samples / nb_players)))
        end
    end

    # Sampling to acheive the previously computed proportion
    for player in 1:nb_players
        other_players = filter(x -> x != player, player_set)
        for subset_size in 1:nb_players
            for sample_index in 1:remaining_samples_per_size[player][subset_size]
                subset = shuffle(other_players)[1:subset_size-1]
                subset_eval = evaluation_function(subset)
                push!(subset, player)
                subset_eval_with_player = evaluation_function(subset)
                push!(sampled_values[player][subset_size], subset_eval_with_player - subset_eval)
            end
        end
    end


    shapley_values = zeros(nb_players)
    for player in 1:nb_players
        shapley_values[player] = sum([sum(sample_list) / length(sample_list) for sample_list in sampled_values[player]]) / nb_players
    end
    return vec(shapley_values)
end


function allocate_remaining_samples(target_proportions::Vector{Float64}, already_allocated_samples::Vector{Int64}, nb_samples_to_dispatch::Int64)::Vector{Int64}
    # This algorithm is used when one wants to allocate a certain number of samples to each event in a stratification event partition. This happens in stratification with sample allocation.
    # Samples have already been allocated and we compute the number of additionnal samples to allocate to fit the target number (or proportion).
    # The process is iterative to take into account that sometimes some event have already been allocated more samples than their target proportion.
    nb_sizes = length(already_allocated_samples)
    sizes_with_remaining_samples = collect(1:nb_sizes)
    finish = false
    while !finish
        finish = true
        target_sum = sum(target_proportions[sizes_with_remaining_samples])
        for subset_size in collect(sizes_with_remaining_samples)
            optimal_nb_sample = nb_samples_to_dispatch * target_proportions[subset_size] / target_sum
            if optimal_nb_sample < already_allocated_samples[subset_size]
                sizes_with_remaining_samples = filter(x -> x != subset_size, sizes_with_remaining_samples)
                nb_samples_to_dispatch -= already_allocated_samples[subset_size]
                finish = false
            end
        end
    end

    target_sum = sum(target_proportions[sizes_with_remaining_samples])
    optimal_nb_sample_per_size = zeros(nb_sizes)
    for subset_size in sizes_with_remaining_samples
        optimal_nb_sample_per_size[subset_size] = nb_samples_to_dispatch * target_proportions[subset_size] / target_sum - already_allocated_samples[subset_size]
    end

    return floor.(Int64, optimal_nb_sample_per_size)
end


function complementary_contribution_neyman_allocation_shapley_values(evaluation_function::Function, nb_players::Int64, nb_evaluations::Int64, min_nb_init_samples::Int64=5)::Vector{Float64}
    # Implements a method for approximating the shapley value. It uses sampling of complementary contributions with stratification according to player position.
    # Moreover, the process of sample allocation presented by Castro et. al. (https://doi.org/10.1145/3588728) is used 
    total_cost = evaluation_function(collect(1:nb_players))
    sampled_values = [[Float64[] for subset_size in 1:nb_players] for player in 1:nb_players] # contains the samples used to estimate the shapley value
    for player in 1:nb_players push!(sampled_values[player][nb_players], total_cost) end
    actionnable_sizes = collect(ceil(Int64, nb_players/2):nb_players-1)
    nb_samples = floor(Int64, nb_evaluations / 2)

    nb_samples_init = floor(Int64, nb_samples / 2)
    already_allocated_samples = zeros(Int64, length(actionnable_sizes))
    # Initial sampling in order to compute the target proportion of samples for each size
    for index in 1:nb_samples
        nb_eval_min, subset_size, ensured_player = minimum([(length(sampled_values[player][subset_size]), subset_size, player) for subset_size in 1:nb_players-1, player in 1:nb_players])
        if nb_eval_min > 0 && index > nb_samples_init break end
        actionnable_size_index = findfirst(size -> size == max(subset_size, nb_players - subset_size), actionnable_sizes)
        already_allocated_samples[actionnable_size_index] += 1

        permutation = shuffle(1:nb_players)
        ensured_player_index = findfirst(player -> player == ensured_player, permutation)
        permutation[1], permutation[ensured_player_index] = permutation[ensured_player_index], permutation[1]
        subset = permutation[1:subset_size]
        complement_subset = permutation[subset_size+1:end]
        complementarity_contribution = evaluation_function(subset) - evaluation_function(complement_subset) 
        for player in subset
            push!(sampled_values[player][subset_size], complementarity_contribution)
        end
        for player in complement_subset
            push!(sampled_values[player][nb_players - subset_size], -complementarity_contribution)
        end
    end


    target_proportions = [sqrt(sum([variance(sampled_values[player][subset_size]) / subset_size + variance(sampled_values[player][nb_players - subset_size]) / (nb_players - subset_size) for player in 1:nb_players])) for subset_size in actionnable_sizes]
    # Computing the remaining samples to allocate
    if sum(target_proportions) == 0
        remaining_samples_per_size = zeros(Int64, length(actionnable_sizes))
    else
        remaining_samples_per_size = allocate_remaining_samples(target_proportions, already_allocated_samples, nb_samples)
    end

    # Sampling to acheive the previously computed proportion
    for (index, subset_size) in enumerate(actionnable_sizes)
        for index2 in 1:remaining_samples_per_size[index]
            permutation = shuffle(1:nb_players)
            subset = permutation[1:subset_size]
            complement_subset = permutation[subset_size+1:end]
            complementarity_contribution = evaluation_function(subset) - evaluation_function(complement_subset) 
            for player in subset
                push!(sampled_values[player][subset_size], complementarity_contribution)
            end
            for player in complement_subset
                push!(sampled_values[player][nb_players - subset_size], -complementarity_contribution)
            end
        end
    end


    shapley_values = [sum([sum(sample_list) / length(sample_list) for sample_list in sampled_values[player]]) / nb_players for player in 1:nb_players]
    return vec(shapley_values)
end



function kernel_shapley_values(evaluation_function::Function, nb_players::Int64, nb_samples::Int64)::Vector{Float64}
     # Implements a method for approximating the shapley value. This algorithm is commonly known as KernelSHAP
    player_set = collect(1:nb_players)
    total_cost = evaluation_function(player_set)

    A = zeros(Float64, nb_players, nb_players)
    b = zeros(nb_players)
    
    weights = [(nb_players-1) / subset_size / (nb_players - subset_size) for subset_size in 1 : nb_players-1]
    remaining_samples_per_size = floor.(weights .* (nb_samples / sum(weights)))
    subset_size = 1
    # sampling subsets
    while sum(remaining_samples_per_size) > 0
        if remaining_samples_per_size[subset_size] <= 0 subset_size += 1 end
        remaining_samples_per_size[subset_size] -= 1
        subset = sample(player_set, subset_size, replace = false)
        is_in_subset = zeros(nb_players)
        is_in_subset[subset] .= 1

        A += is_in_subset * is_in_subset'
        b += is_in_subset .* evaluation_function(subset)
    end

    # Solving the quadratic program "min xAx + bx" whose optimum x is the shapley value.
    AA = A ./ nb_samples
    A = zeros(Float64, nb_players+1, nb_players+1)
    A[1:end-1, 1:end-1] = AA
    A[end, 1:end-1] .= 1
    A[1:end-1, end] .= 1
    b = [b ./ nb_samples; total_cost]
    inv_A = inv(A)

    
    shapley_values = inv_A * b

    return vec(shapley_values[1:end-1])
end