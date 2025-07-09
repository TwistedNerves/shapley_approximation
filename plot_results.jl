using JLD2


function mean_and_variance_and_quartiles(value_list::Vector{Float64})::Tuple{Float64, Float64, Float64, Float64, Float64}
    mean = sum(value_list) / length(value_list)
    variance = sum((value_list .- mean).^2) / length(value_list)
    l = sort(value_list)
    low_quartile = l[floor(Int64, length(value_list) * 0.25)]
    median = l[floor(Int64, length(value_list) * 0.5)]
    high_quartile = l[floor(Int64, length(value_list) * 0.75)]
    return mean, variance, low_quartile, median, high_quartile
end


function instance_name_from_index(index::Int64, path::String)::String
    list_files = readdir(path)
    sort!(list_files)
    # println(list_files[1:20])
	return list_files[index]
end
instance_name_from_index(1, "/home/francois-lamothe/Desktop/shapley_approximation/datasets/varying_variance_tradeoff/")

result_dict = load_object("/home/francois-lamothe/Desktop/shapley_approximation/processed_results/exp_pfcalcul_2025-07-04T11:59:04.643.jld2")

# algorithm_list = ["kernel", "mc no stratif", "mc position stratif", "mc player stratif", "mc both stratif", "cc position stratif", "cc both stratif", "cc position stratif neyman", "mc position stratif neyman"]
algorithm_list = ["mc no stratif", "mc position stratif", "cc position stratif", "cc position stratif neyman", "mc position stratif neyman"]
# algorithm_list = ["mc no stratif", "cc position stratif", "cc position stratif neyman", "cc both stratif"]
# algorithm_list = ["mc no stratif", "mc position stratif", "mc player stratif", "mc both stratif"]
# algorithm_list = ["cc position stratif neyman", "mc position stratif", "mc both stratif"]
# algorithm_list = ["mc position stratif", "mc position stratif neyman"]
# algorithm_list = ["mc no stratif", "kernel"]
# dataset_name = "varying_variance_tradeoff"
# dataset_name = "varying_sparseness"
dataset_name = "airport"
# dataset_name = "knapsack"
# dataset_name = "voting"

# nb_players_list = [10, 20, 50, 100]
# sample_multiplier = 20
# res_dict = Dict()
# for algorithm_name in algorithm_list
#     res_dict[algorithm_name] = (Float64[], Float64[], Float64[])
#     for nb_players in nb_players_list
#         nb_samples  = sample_multiplier * nb_players * nb_players
#         res_list = result_dict[algorithm_name][dataset_name][nb_players][nb_samples]
#         mean, variance, low_quartile, median, high_quartile = mean_and_variance_and_quartiles(res_list)
#         std = sqrt(variance)
#         push!(res_dict[algorithm_name][1], low_quartile)
#         push!(res_dict[algorithm_name][2], median)
#         push!(res_dict[algorithm_name][3], high_quartile)
#     end
# end
# abscisse = nb_players_list
# title = "Dataset '$(replace(dataset_name, "_"=>" "))' with $(sample_multiplier)n² samples"
# x_title = "Number of players"

nb_players = 100
sample_multiplier_list = [1, 4, 20, 100]
# sample_multiplier_list = [1, 4, 20, 100, 300, 1000]
res_dict = Dict()
for algorithm_name in algorithm_list
    res_dict[algorithm_name] = (Float64[], Float64[], Float64[])
    for sample_multiplier in sample_multiplier_list
        nb_samples  = sample_multiplier * nb_players * nb_players
        if haskey(result_dict[algorithm_name][dataset_name][nb_players], nb_samples)
            res_list = result_dict[algorithm_name][dataset_name][nb_players][nb_samples]
            if length(res_list) < 20
                println("$algorithm_name, $nb_samples")
            end
            mean, variance, low_quartile, median, high_quartile = mean_and_variance_and_quartiles(res_list)
            std = sqrt(variance)
            push!(res_dict[algorithm_name][1], low_quartile)
            push!(res_dict[algorithm_name][2], median)
            push!(res_dict[algorithm_name][3], high_quartile)
        end
    end
end
abscisse = sample_multiplier_list .* nb_players^2
title = "Dataset '$(replace(dataset_name, "_"=>" "))' with $(nb_players) players"
x_title = "Number of samples"


# nb_players = 100
# nb_samples  = 100 * nb_players * nb_players
# # sample_multiplier_list = [1, 4, 20, 100, 300, 1000]
# res_dict = Dict()
# for algorithm_name in algorithm_list
#     res_dict[algorithm_name] = (Float64[], Float64[], Float64[])
#     if haskey(result_dict[algorithm_name][dataset_name][nb_players], nb_samples)
#         res_list = result_dict[algorithm_name][dataset_name][nb_players][nb_samples]
#         # if algorithm_name == "mc player stratif" && dataset_name == "varying_sparseness"
#         #     insert!(res_list, 42, 0)
#         # end
#         start = 1
#         for i in 1:4
#             mean, variance, low_quartile, median, high_quartile = mean_and_variance_and_quartiles(res_list[start:start+19])
#             std = sqrt(variance)
#             push!(res_dict[algorithm_name][1], low_quartile)
#             push!(res_dict[algorithm_name][2], median)
#             push!(res_dict[algorithm_name][3], high_quartile)
#             start += 20
#         end
#     end
# end
# abscisse = [0., 0.33, 0.66, 1.]
# title = "Dataset '$(replace(dataset_name, "_"=>" "))' with $(nb_players) players and 100n² samples"
# x_title = "Sparseness coefficient"

color_dict = Dict("kernel" => :brown, "mc no stratif" => :black, "mc position stratif" => :blue, "mc player stratif" => :green, "mc both stratif" => :indigo, "cc position stratif" => :red, "cc both stratif" => :orange, "cc position stratif neyman" => :yellow, "mc position stratif neyman" => :hotpink)

using PlotlyJS
trace_list = typeof(scatter(;x=abscisse, y=abscisse))[]
for algorithm_name in algorithm_list
    low_list, middle_list, high_list = res_dict[algorithm_name]
    used_abscisse = abscisse[1:length(middle_list)]
    trace_mean = scatter(;x=used_abscisse, y=middle_list, mode="lines", line_color=color_dict[algorithm_name], name=algorithm_name)
    trace_high = scatter(;x=used_abscisse, y=high_list, mode="lines", line=attr(width=0.5), marker_color=color_dict[algorithm_name], showlegend = false)
    trace_low = scatter(;x=used_abscisse, y=low_list, marker_color=color_dict[algorithm_name], fill="tonexty", line=attr(width=0.5), mode="lines", showlegend = false)
    push!(trace_list, trace_mean)
    push!(trace_list, trace_high)
    push!(trace_list, trace_low)
    
end
display(plot(trace_list, Layout(showlegend = true, xaxis=attr(type="log", tickfont=attr(size=24)), xaxis_title=x_title, yaxis=attr(type="log"), font_size=24, yaxis_title="Mean normalized error")))