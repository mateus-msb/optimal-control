# ===========================================================
# Otimização de Volante de Inércia (Flywheel)
# PME 5205 - CONTROLE ÓTIMO DE SISTEMAS DINÂMICOS
# EXAME - 1º PERÍODO DE 2026
# Aluno: Mateus Silva Borges
# Método: Algoritmo Genético (GA) (Metaheuristics.jl)
# ===========================================================

using Metaheuristics
using Printf
using Random
using Plots
using Plots.Measures

## CONSTANTES FÍSICAS E ESPECIFICAÇÕES DO PROBLEMA ---
const m_max = 68.00       # Massa máxima permitida (kg) ≈ 150 lb
const d_max = 0.635       # Diâmetro máximo permitido (m) ≈ 25 in
const h_max = 1.000       # Altura máxima permitida (m)
const ω_min = 2000.0 * π / 30.0  # Velocidade angular mínima (rad/s) ≈ 2000 rpm
const ω_max = 4000.0 * π / 30.0  # Velocidade angular máxima (rad/s) ≈ 4000 rpm
const σ_max = 1.379e8     # Tensão máxima permitida (Pa) ≈ 20000 psi
const ρ = 7833.4          # Massa específica do material (kg/m³) - aço
const ν = 0.3             # Coeficiente de Poisson
const g = 9.80665         # Aceleração da gravidade (m/s²)

# Funções Auxiliares
function calcular_tensao(d, ω)
    σ = (ρ * (3.0 + ν) * (ω^2) * (d^2)) / 8.0
    return σ
end

function calcular_energia(d, h, ω)
    J = (ρ * π * (d^4) * h) / 32.0
    E = 0.5 * J * (ω^2)
    return E
end

function objetivo_problema_1(x)
    d = x[1]
    h = x[2]
    ω = 3000.0 * π / 30.0

    # Função Objetivo: Maximizar energia (minimizar o negativo da energia)
    f_obj = -calcular_energia(d, h, ω)

    # Restrição de desigualdade de massa
    massa = ρ * (π * d^2 / 4.0) * h
    g1 = massa - m_max

    # Restrição de desigualdade de Tensão
    σ = calcular_tensao(d, ω)
    g2 = σ^2 - σ_max^2

    # Vetor de restrições de desigualdade
    g = [g1, g2]
    
    # Sem restrições de igualdade
    h_eq = [0.0]

    return f_obj, g, h_eq
end

function objetivo_problema_2(x)
    d = x[1]
    h = x[2]
    ω = x[3]

    # Função Objetivo: Maximizar energia (minimizar o negativo)
    f_obj = -calcular_energia(d, h, ω)

    # Restrição de desigualdade de massa
    massa = ρ * (π * d^2 / 4.0) * h
    g1 = massa - m_max

    # Restrição de desigualdade de Tensão
    σ = calcular_tensao(d, ω)
    g2 = σ^2 - σ_max^2
    
    g = [g1, g2]
    
    # Sem restrições de igualdade
    h_eq = [0.0]

    return f_obj, g, h_eq
end

function plot_objetivo(name)
    
    d_intervalo = range(0.001, d_max, length=200); 
    h_intervalo = range(0.001, h_max, length=200);

    f_plot(d, h) = objetivo_problema_1([d, h])[1]
    g1_plot(d, h) = objetivo_problema_1([d, h])[2][1]

    contour_plot = contourf(d_intervalo, h_intervalo, f_plot,
        levels = 20,
        title = "Otimização com Restrições", 
        framestyle = :box,
        grid = :dot,
        gridalpha = 0.6,
        xlabel = "Diâmetro (m)",
        ylabel = "Altura (m)",
        size = (900, 600),
        right_margin = 20mm,
        left_margin = 3mm,
    );
    contour!(d_intervalo, h_intervalo, g1_plot,
        levels = [0.0],
        color = :red,
        linestyle = :dash,
        linewidth = 2.0,
        label = "Restrição de Massa",
    );

    # Exibe o resultado final com tudo sobreposto
    display(contour_plot)
    savefig(contour_plot, "$(name)_contorno.png")
end

function plot_convergence(result, name)

    # fitness
    f_calls, best_f_value = convergence(result)
    
    conv_plot = plot(f_calls, -best_f_value);
    plot!(
        title="Convergência",
        xlabel="Chamadas da Função Objetivo",
        ylabel="Energia Armazenada",
        label="GA",
        framestyle=:box,
        grid=:dot,
        size=(600, 400),
        gridalpha=0.6,
        left_margin=3mm,
        titlefontsize=12,
        legendfontsize=10
        );
    display(conv_plot);
    savefig(conv_plot, "$(name)_convergencia.png")

    # population
    _convergence = convergence(result);
    n_iterations = length(_convergence[1]);

    indices_momentos = [
        1,
        2,
        3,
        4,
        round(Int, 0.10 * n_iterations),
        round(Int, 0.15 * n_iterations),
        round(Int, 0.50 * n_iterations),
        n_iterations
    ]
    list_plots = Plots.Plot[]
    is_3d = size(positions(result.convergence[1]), 2) == 3

    for i in indices_momentos

        X = positions(result.convergence[i])
        x = minimizer(result.convergence[i])

        if size(X, 2) == 3
            p = plot(
                title="Geração $(i)",
                xlabel="d (m)",
                xlim=(0, d_max),
                ylabel="h (m)",
                ylim=(0, h_max),
                zlabel="ω (rad/s)",
                zlim=(ω_min, ω_max),
                framestyle=:box,
                grid=:dot,
                gridalpha=0.6,
                size=(400, 400),
                margin=5mm,
            );
            scatter3d!(p, X[:,1], X[:,2], X[:,3], label="")
            scatter3d!(p, x[1:1], x[2:2], x[3:3], label="")
        else
            p = plot(
                title="Geração $(i)",
                xlabel="d (m)",
                xlim=(0, d_max),
                ylabel="h (m)",
                ylim=(0, h_max),
                framestyle=:box,
                grid=:dot,
                gridalpha=0.6,
                left_margin=5mm,
                bottom_margin=5mm,
            );
            scatter!(p, X[:,1], X[:,2], label="", xlim=(0, d_max), ylim=(0, h_max))
            scatter!(p, x[1:1], x[2:2], label="")
        end

        push!(list_plots, p)
    end

    n = length(list_plots)
    layout_pop = (div(n, 2), 2)
    size_pop = is_3d ? (800, 400 * div(n, 2)) : (1200, 350 * div(n, 2))

    subplot_final = plot(list_plots..., 
        layout = layout_pop, 
        plot_title = "Evolução da População",
        size = size_pop,
        left_margin=5mm,
        bottom_margin=5mm,
    );
    display(subplot_final);
    savefig(subplot_final, "$(name)_populacao.png")
end


## PROBLEMA I: Otimização com d e h como variáveis (Velocidade ω = 3000 rpm fixa)
# Variáveis de decisão: x = [d, h]
# d ∈ [0.001, 0.635] (m)
# h ∈ [0.001, 1.000] (m) - limite superior de h arbitrado de forma ampla

println("\n OTIMIZANDO PROBLEMA I")

# Limites das variáveis: [d, h]
bounds = boxconstraints(
    lb = [0.001, 0.001],
    ub = [d_max, h_max]
);

options = Options(seed=1, store_convergence=true);

ga_1 = GA(
    N = 50,
    selection = TournamentSelection(K=3, N=50),
    crossover = UniformCrossover(p=0.80),
    mutation = PolynomialMutation(η=5, p=1/2, bounds = bounds),
    environmental_selection = ElitistReplacement(),
    options=options
    )

result_1 = optimize(objetivo_problema_1,bounds,ga_1)

# Extração dos melhores parâmetros
best_x1 = minimizer(result_1)

# Convertendo de volta para positivo (Maximização)
best_f1 = -minimum(result_1)

d_opt1 = best_x1[1]
h_opt1 = best_x1[2]
ω_opt1 = 3000.0 * π / 30.0
ω_opt1_rpm = ω_opt1 * 30.0 / π
massa_opt1 = ρ * (π * d_opt1^2 / 4.0) * h_opt1
σ_opt1 = calcular_tensao(d_opt1, ω_opt1)

println("\n[RESULTADO DO PROBLEMA I]")
@printf("  Diâmetro Ótimo (d):   %8.4f m  (%7.2f mm)\n", d_opt1, d_opt1 * 1000.0)
@printf("  Altura Ótima (h):      %8.4f m  (%7.2f mm)\n", h_opt1, h_opt1 * 1000.0)
@printf("  Velocidade Angular:    %8.2f rad/s  (%8.2f rpm)\n", ω_opt1, ω_opt1_rpm)
@printf("  Massa Resultante:      %8.4f kg  (Limite: %.2f kg)\n", massa_opt1, m_max)
@printf("  Tensão de Pico:        %8.2e Pa (Limite: %.2e Pa)\n", σ_opt1, σ_max)
@printf("  Energia Armazenada:    %8.2f J\n", best_f1)

# Visualizar
plot_objetivo("problema_1")
plot_convergence(result_1, "problema_1")


## PROBLEMA II: Otimização com d, h e ω como variáveis (ω ∈ [2000, 4000] rpm)
# Variáveis de decisão: x = [d, h, ω]
# d ∈ [0.001, 0.635] (m)
# h ∈ [0.001, 1.000] (m)
# ω ∈ [2000π/30, 4000π/30] (rad/s)

println("\nOTIMIZANDO PROBLEMA II")

# Limites das variáveis: [d, h, ω]
bounds_2 = boxconstraints(
    lb = [0.001, 0.001, ω_min],
    ub = [d_max, h_max, ω_max]
);

options = Options(seed=1, store_convergence=true);
ga_2 = GA(
    N = 50,
    selection = TournamentSelection(K=3, N=50),
    crossover = UniformCrossover(p=0.80),
    mutation = PolynomialMutation(η=10, p=1/3, bounds = bounds_2),
    environmental_selection = ElitistReplacement(),
    options=options
    )

result_2 = optimize(objetivo_problema_2, bounds_2, ga_2)

best_x2 = minimizer(result_2)
best_f2 = -minimum(result_2)

d_opt2 = best_x2[1]
h_opt2 = best_x2[2]
ω_opt2 = best_x2[3]
ω_opt2_rpm = ω_opt2 * 30.0 / π
massa_opt2 = ρ * (π * d_opt2^2 / 4.0) * h_opt2
σ_opt2 = calcular_tensao(d_opt2, ω_opt2)

println("\n[RESULTADO DO PROBLEMA II]")
@printf("  Diâmetro Ótimo (d):   %8.4f m  (%7.2f mm)\n", d_opt2, d_opt2 * 1000.0)
@printf("  Altura Ótima (h):      %8.4f m  (%7.2f mm)\n", h_opt2, h_opt2 * 1000.0)
@printf("  Velocidade Ótima (ω): %8.2f rad/s  (%8.2f rpm)\n", ω_opt2, ω_opt2_rpm)
@printf("  Massa Resultante:      %8.4f kg  (Limite: %.2f kg)\n", massa_opt2, m_max)
@printf("  Tensão de Pico:        %8.2e Pa (Limite: %.2e Pa)\n", σ_opt2, σ_max)
@printf("  Energia Armazenada:    %8.2f J\n", best_f2)
println("="^80)

plot_convergence(result_2, "problema_2")
