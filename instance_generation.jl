function read_symetric_sum_instance(file_path::String)::Tuple{Function, Function}
    symetric_game_list, nb_players = load_object(file_path)
    evaluation_function = player_list -> evaluate_symetric_sum_games(symetric_game_list, player_list)
    shapley_evaluator = () -> shapley_evaluator_symetric_sum_games(symetric_game_list, nb_players)
    return evaluation_function, shapley_evaluator
end


function generate_airport_as_symetric_sum_instance(nb_players::Int64, file_path::String="")::Tuple{Function, Function}
    if nb_players >= 127
        symetric_game_list = Tuple{Vector{Int64}, Vector{Float64}}[]
    else
        symetric_game_list = Tuple{Int128, Vector{Float64}}[]
    end


    player_values = floor.(rand(nb_players) * 100) .+ 1

    player_and_values = [(player, player_values[player]) for player in 1:nb_players]
    sort!(player_and_values, by = x -> x[2])

    included_players = collect(1:nb_players)
    old_value = 0.
    for (player, value) in player_and_values

        if nb_players >= 127
            is_in_game = zeros(Int64, nb_players)
            is_in_game[included_players] .= 1
        else
            is_in_game::Int128 = sum([Int128(2)^(player-1) for player in included_players])
        end

        object_weight = value - old_value
        nb_included_players = length(included_players)
        game_values = ones(nb_included_players) .* object_weight
        push!(symetric_game_list, (is_in_game, game_values))

        included_players = filter(x -> x != player, included_players)
        old_value = value
    end

    if file_path != ""
        save_object(file_path, (symetric_game_list, nb_players))
    end

    evaluation_function = player_list -> evaluate_symetric_sum_games(symetric_game_list, player_list)
    shapley_evaluator = () -> shapley_evaluator_symetric_sum_games(symetric_game_list, nb_players)
    return evaluation_function, shapley_evaluator
end


function generate_symetric_sum_instance(nb_players::Int64, nb_symetric_games::Int64, create_game_values::Function, file_path::String="", size_distribution_factor::Float64=1.)::Tuple{Function, Function}
    # This is the main function used to generate instance of cooperative games.
    # A symetric sum game is composed of a sum of subgames which are all symetric with respect to the players inside these subgames.
    # In order to quicken the computations, we represent some binary vectors with Int128 where each bit of the number corresponds to an entry of the vector. This trick is used when their are less the 128 players in the game.
    symetric_game_list = Tuple{Int128, Vector{Float64}}[]
    if nb_players >= 127
        symetric_game_list = Tuple{Vector{Int64}, Vector{Float64}}[]
    else
        symetric_game_list = Tuple{Int128, Vector{Float64}}[] # represent a binary vector with an Int128
    end

    for game_index in 1:nb_symetric_games # each loop creates one subgame
        interpolation_coeff = max(0, 1 - rand()*size_distribution_factor)
        game_size = floor(Int64, exp(log(2) + interpolation_coeff * (log(nb_players) - log(2))))
        # game_size = floor(Int64, nb_players * 0.8)
        included_players = collect(shuffle(1:nb_players))[1:game_size] # which players participate in the game

        if nb_players >= 127
            is_in_game = zeros(Int64, nb_players)
            is_in_game[included_players] .= 1
        else
            is_in_game::Int128 = sum([Int128(2)^(player-1) for player in included_players])
        end
        
        nb_included_players = length(included_players)
        game_values = create_game_values(nb_included_players)
        game_values = game_values ./ game_values[end]

        push!(symetric_game_list, (is_in_game, game_values))
    end

    if file_path != ""
        save_object(file_path, (symetric_game_list, nb_players)) # saving the game in a file using JLD2
    end

    evaluation_function = player_list -> evaluate_symetric_sum_games(symetric_game_list, player_list)
    shapley_evaluator = () -> shapley_evaluator_symetric_sum_games(symetric_game_list, nb_players)
    return evaluation_function, shapley_evaluator
end


function create_monotone_function(nb_players::Int64)::Vector{Float64}
    game_values = zeros(nb_players)
    game_values[1] = 1
    for index in 2:nb_players
        game_values[index] = game_values[index-1] + rand()
    end
    return game_values
end

function create_random_function(nb_players::Int64, distribution_min::Float64=0., distribution_spread::Float64=1.)::Vector{Float64}
    return vec(rand(nb_players) .* distribution_spread .+ distribution_min)
end


function create_voting_function(nb_players::Int64, exponent::Float64=1.)::Vector{Float64}
    size_of_winning_coalition = floor(Int64,(rand()^exponent) * nb_players) + 1
    game_values = zeros(nb_players)
    game_values[size_of_winning_coalition:end] .= 1
    return vec(game_values)
end


function create_knapsack_function(nb_players::Int64)::Vector{Float64}
    return vec(ones(nb_players))
end



function evaluate_symetric_sum_games(symetric_game_list::Vector{Tuple{Vector{Int64}, Vector{Float64}}}, player_list::Vector{Int64})::Float64
    total_value = 0
    for (is_in_game, game_values) in symetric_game_list
        nb_present_players = sum(is_in_game[player_list])
        if nb_present_players > 0
            total_value += game_values[nb_present_players]
        end
    end
    return total_value
end


function evaluate_symetric_sum_games(symetric_game_list::Vector{Tuple{Int128, Vector{Float64}}}, player_list::Vector{Int64})::Float64
    total_value = 0
    is_present::Int128 = sum([Int128(2)^(player-1) for player in player_list])
    for (is_in_game, game_values) in symetric_game_list
        nb_present_players = count_ones(is_in_game & is_present)
        total_value += nb_present_players > 0 ? game_values[nb_present_players] : 0
    end
    return total_value
end


function shapley_evaluator_symetric_sum_games(symetric_game_list::Vector{Tuple{Vector{Int64}, Vector{Float64}}}, nb_players::Int64)::Vector{Float64}
    shapley_value = zeros(nb_players)
    for (is_in_game, game_values) in symetric_game_list
        shapley_value .+= is_in_game .* game_values[end]/sum(is_in_game)
    end
    return shapley_value
end

function shapley_evaluator_symetric_sum_games(symetric_game_list::Vector{Tuple{Int128, Vector{Float64}}}, nb_players::Int64)::Vector{Float64}
    shapley_value = zeros(nb_players)
    for (is_in_game, game_values) in symetric_game_list
        is_in_game = [(is_in_game>>(i-1))%2 for i in 1:nb_players]
        shapley_value .+= is_in_game .* game_values[end]/sum(is_in_game)
    end
    return shapley_value
end



function generate_spanning_tree_instance(nb_players::Int64)::Tuple{Function, Function}
    evaluation_function = player_list -> evaluate_spanning_tree_game(nb_players, player_list)
    shapley_evaluator = () -> vec(ones(nb_players) .* (nb_players-1) ./ nb_players)
    return evaluation_function, shapley_evaluator
end

function evaluate_spanning_tree_game(nb_players::Int64, player_list::Vector{Int64})::Float64
    if length(player_list) == 0 return 0 end
    player_list = sort(player_list)
    largest_gap = maximum([player_list[i+1] - player_list[i] for i in 1:(length(player_list)-1)], init=0.)
    largest_gap = max(largest_gap, nb_players - player_list[end] + player_list[1])
    return nb_players - largest_gap
end
