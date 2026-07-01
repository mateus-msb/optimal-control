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

function objetivo_problema_1_value(x)
    f_obj, g, h_eq = objetivo_problema_1(x)
    return f_obj
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

function plot_objetivo()
    d_intervalo = range(0.001, d_max, length=200); 
    h_intervalo = range(0.001, h_max, length=200);
    f_plot(d, h) = objetivo_problema_1([d, h])[1]

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
    )

    # Exibe o resultado final com tudo sobreposto
    display(contour_plot)
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

result_1 = optimize(
    objetivo_problema_1,
    bounds,
    GA(
        N = 50,
        p_mutation = 0.10,
        p_crossover = 0.8,
        mutation = PolynomialMutation(bounds = bounds),
        options=options
        )
        )

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
X_1 = positions(result_1)
convergence_1 = convergence(result_1);
n_iterations = length(convergence_1[1]);

f_calls, best_f_value = convergence(result_1)

conv_plot = plot(f_calls, -best_f_value, label="GA");
plot!(
    title="Convergence",
    xlabel="function calls",
    ylabel="fitness",
    framestyle=:box,
    grid=:dot,
    size=(600, 400),
    gridalpha=0.6,
    left_margin=3mm,
    );
display(conv_plot);

indices_momentos = [
    1,
    round(Int, 0.15 * n_iterations),
    round(Int, 0.25 * n_iterations),
    round(Int, 0.50 * n_iterations),
    round(Int, 0.75 * n_iterations),
    n_iterations
]


for i in indices_momentos
    p = plot(
    title="Population Evolution",
    xlabel="Diametro",
    ylabel="Altura",
    framestyle=:box,
    grid=:dot,
    size=(600, 400),
    gridalpha=0.6,
    left_margin=3mm,
    );
    X = positions(result_1.convergence[i])
    scatter!(p[1], X[:,1], X[:,2], label="", xlim=(0, d_max), ylim=(0, h_max), title="Population")
    x = minimizer(result_1.convergence[i])
    scatter!(p[1], x[1:1], x[2:2], label="")
    display(p)
end
display(p)

## PROBLEMA II: Otimização com d, h e ω como variáveis (ω ∈ [2000, 4000] rpm)
# Variáveis de decisão: x = [d, h, ω]
# d ∈ [0.001, 0.635] (m)
# h ∈ [0.001, 1.000] (m)
# ω ∈ [2000π/30, 4000π/30] (rad/s)

function executar_otimizacao()
    # --- RESOLVENDO PROBLEMA I ---
    println("\n>>> OTIMIZANDO PROBLEMA I (Velocidade fixa em 3000 rpm)...")
    
    # Limites das variáveis: [d, h]
    bounds = boxconstraints(
        lb = [0.001, 0.001],
        ub = [d_max, h_max]
    )

    result_1 = optimize(objetivo_problema_1, bounds, GA(
        N = 120,
        p_mutation = 0.15,
        p_crossover = 0.8,
        mutation = PolynomialMutation(bounds = bounds)
    ))
    
    # Extração dos melhores parâmetros
    best_x1 = minimizer(result_1)
    best_f1 = -minimum(result_1) # Convertendo de volta para positivo (Maximização)
    
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

    # --- RESOLVENDO PROBLEMA II ---
    println("\n" * "-"^80)
    println("\n>>> OTIMIZANDO PROBLEMA II (Velocidade variável no intervalo [2000, 4000] rpm)...")

    # Limites das variáveis: [d, h, ω]
    bounds_2 = boxconstraints(
        lb = [0.001, 0.001, 2000.0 * π / 30.0],
        ub = [d_max, h_max, 4000.0 * π / 30.0]
    )

    ga_2 = GA(
        N = 120,
        p_mutation = 0.15,
        p_crossover = 0.8,
        mutation = PolynomialMutation(bounds = bounds_2)
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
    
end

# Inicia a otimização
executar_otimizacao()