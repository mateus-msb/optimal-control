# ==============================================================================
# Otimização de Volante de Inércia (Flywheel)
# PME 5205 - CONTROLE ÓTIMO DE SISTEMAS DINÂMICOS
# EXAME - 1º PERÍODO DE 2026
# Aluno: Mateus Silva Borges
# Método: Algoritmo Genético (GA) (Metaheuristics.jl)
# ==============================================================================

using Metaheuristics
using Printf
using Random
using Plots

## CONSTANTES FÍSICAS E ESPECIFICAÇÕES DO PROBLEMA ---
const m_max = 68.00       # Massa máxima permitida (kg) ≈ 150 lb
const d_max = 0.635       # Diâmetro máximo permitido (m) ≈ 25 in
const h_max = 2.000       # Altura máxima permitida (m)
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
    g2 = σ - σ_max

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
    g2 = σ - σ_max
    
    g = [g1, g2]
    
    # Sem restrições de igualdade
    h_eq = [0.0]

    return f_obj, g, h_eq
end

## PROBLEMA I: Otimização com d e h como variáveis (Velocidade ω = 3000 rpm fixa)
# Variáveis de decisão: x = [d, h]
# d ∈ [0.001, 0.635] (m)
# h ∈ [0.001, 2.000] (m) - limite superior de h arbitrado de forma ampla

println("\n OTIMIZANDO PROBLEMA I")

# Limites das variáveis: [d, h]
bounds = boxconstraints(
    lb = [0.001, 0.001],
    ub = [d_max, h_max]
)

options = Options(seed=1, store_convergence=true)

result_1 = optimize(
    objetivo_problema_1,
    bounds,
    GA(
        N = 100,
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
convergence_1 = convergence(result_1)
n_iterations = length(convergence_1[1])

f_calls, best_f_value = convergence(result_1)

indices_momentos = [
    1,
    round(Int, 0.25 * n_iterations),
    round(Int, 0.50 * n_iterations),
    round(Int, 0.75 * n_iterations),
    n_iterations
]

# Array único que vai alimentar o layout (5, 2)
todos_os_subplots = []

for idx in indices_momentos
    pop = historico_populacoes[idx]
    geracao = historico_geracoes[idx]
    
    # 1. PRIMEIRA COLUNA: Gráfico de Dispersão da População
    p_pop = scatter(
        pop[:, 1], pop[:, 2],
        xlim = (0.0, d_max * 1.1),
        ylim = (0.0, h_max * 1.1),
        xlabel = "d (m)",
        ylabel = "h (m)",
        title = "População - Geração $geracao",
        legend = false,
        markersize = 3,
        markeralpha = 0.6,
        color = :blue
    )
    # Marca de estrela na solução ótima global
    scatter!(p_pop, [d_opt1], [h_opt1], color = :red, markersize = 5, marker = :star)
    
    # 2. SEGUNDA COLUNA: Evolução do Fitness acumulado até este momento
    p_fitness = plot(
        f_calls[1:idx], -best_f_value[1:idx],
        xlim = (0, f_calls[end]), # Mantém o eixo X fixo para ver a evolução avançando
        ylim = (0, best_f1 * 1.1),  # Mantém o eixo Y fixo para escala comparativa
        xlabel = "Avaliações",
        ylabel = "Energia (J)",
        title = "Evolução do Fitness",
        linewidth = 2,
        color = :darkgreen,
        legend = false
    )
    
    # Adiciona sequencialmente na lista (População vira Coluna 1, Fitness vira Coluna 2)
    push!(todos_os_subplots, p_pop)
    push!(todos_os_subplots, p_fitness)
end

# Criando a Matrix de Subplots (5 linhas, 2 colunas)
plot_final = plot(
    todos_os_subplots...,
    layout = (5, 2),
    size = (1000, 1400) # Redimensionado para dar espaçamento vertical adequado às 5 linhas
)

# Exibe e salva
display(plot_final)


## PROBLEMA II: Otimização com d, h e ω como variáveis (ω ∈ [2000, 4000] rpm)
# Variáveis de decisão: x = [d, h, ω]
# d ∈ [0.001, 0.635] (m)
# h ∈ [0.001, 2.000] (m)
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
executar_otimizacao_1()