using Plots

function plot_switching_curves()

    p = plot(title="Plano de Fase",
             xlabel="x₁", ylabel="x₂",
             aspect_ratio=:equal,
             grid=:dot,
             legend=:outertopright,
             framestyle=:box,
             size=(800, 400),
             gridalpha=0.6,
             legendfontsize=10)

    hline!(p, [1], color=:red, linestyle=:solid, linewidth=1.5, label="Restrição |x₂| = 1")
    hline!(p, [-1], color=:red, linestyle=:solid, linewidth=1.5, label="")

    x2_lower = range(-1, 0, length=200)
    x1_lower = 0.5 .* (x2_lower.^2)
    plot!(p, x1_lower, x2_lower, color=:orange, linewidth=2.5, label="u = +1")

    x2_upper = range(0, 1, length=200)
    x1_upper = -0.5 .* (x2_upper.^2)
    plot!(p, x1_upper, x2_upper, color=:blue, linewidth=2.5, label="u = -1")

    # Eixos de referência
    hline!(p, [0], color=:black, linewidth=1.2, label="")
    vline!(p, [0], color=:black, linewidth=1.2, label="")

    # Destaque dos alvos
    scatter!(p, [0], [0], color=:green, markershape=:circle, markersize=5, label="Origem Alvo x(t_f)")

    xlims!(p, -2.0, 2.0)
    ylims!(p, -1.5, 1.5)

    return p
end 

function plot_example_curve(p, coord)
    x1_0, x2_0 = coord
        
    # CASO 1: Ponto (-1, -1) -> Está sobre a restrição inferior
    if x1_0 == -1 && x2_0 == -1
        # Arco 1: u = +1 (Acelera para entrar na região permitida)
        # Trajetória parabólica: x₁ = 0.5*x₂² - 1.5 (vai de x₂=-1 até x₂=1)
        x2_arc1 = range(-1, 1, length=150)
        x1_arc1 = 0.5 .* (x2_arc1.^2) .- 1.5
        plot!(p, x1_arc1, x2_arc1, color=:orange, linestyle=:dash, linewidth=2, label="Trajetória (-1,-1)")
        quiver!(p, [-1.5], [0.0], quiver=([0.01], [0.2]), color=:orange, linewidth=1.5) # Seta

        # Arco 2: u = 0 (Bate na restrição superior x₂=1 e conduz horizontalmente)
        # Vai de x₁ = -1 até x₁ = -0.5
        x1_arc2 = range(-1, -0.5, length=100)
        x2_arc2 = ones(100)
        plot!(p, x1_arc2, x2_arc2, color=:gray, linestyle=:dash, linewidth=2, label="Fronteira ativa (u = 0)")
        quiver!(p, [-0.75], [1.0], quiver=([0.15], [0.0]), color=:gray, linewidth=1.5) # Seta

        # Arco 3: u = -1 (Chega na curva Γ⁻ e freia em direção à origem)
        # Trajetória parabólica final: x₁ = -0.5*x₂² (de x₂=1 até x₂=0)
        x2_arc3 = range(1, 0, length=100)
        x1_arc3 = -0.5 .* (x2_arc3.^2)
        plot!(p, x1_arc3, x2_arc3, color=:blue, linestyle=:dash, linewidth=2, label="")
        quiver!(p, [-0.125], [0.5], quiver=([0.15], [-0.3]), color=:blue, linewidth=1.5) # Seta
        
    # CASO 2: Ponto (1.5, 0) -> Fora das curvas de chaveamento
    elseif x1_0 == 1.5 && x2_0 == 0
        # Arco 1: u = -1 (Começa a frear/deslocar para a esquerda)
        # Trajetória parabólica: x₁ = -0.5*x₂² + 1.5 (vai de x₂=0 até x₂=-1)
        x2_arc1 = range(0, -1, length=150)
        x1_arc1 = -0.5 .* (x2_arc1.^2) .+ 1.5
        plot!(p, x1_arc1, x2_arc1, color=:blue, linestyle=:dash, linewidth=2, label="Trajetória (1.5,0)")
        quiver!(p, [1.375], [-0.5], quiver=([-0.1], [-0.2]), color=:blue, linewidth=1.5) # Seta

        # Arco 2: u = 0 (Bate na restrição inferior x₂=-1 e conduz horizontalmente)
        # Vai de x₁ = 1.5 até x₁ = 0.5
        x1_arc2 = range(1.5, 0.5, length=100)
        x2_arc2 = -ones(100)
        plot!(p, x1_arc2, x2_arc2, color=:gray, linestyle=:dash, linewidth=2, label="")
        quiver!(p, [0.8], [-1.0], quiver=([-0.15], [0.0]), color=:gray, linewidth=1.5) # Seta

        # Arco 3: u = +1 (Chega na curva Γ⁺ em (0.5, -1) e entra na parábola final até a origem)
        x2_arc3 = range(-1, 0, length=100)
        x1_arc3 = 0.5 .* (x2_arc3.^2)
        plot!(p, x1_arc3, x2_arc3, color=:orange, linestyle=:dash, linewidth=2, label="")
        quiver!(p, [0.125], [-0.5], quiver=([-0.15], [0.3]), color=:orange, linewidth=1.5) # Seta
    end
    
    # Identifica o ponto inicial inserido
    scatter!(p, [x1_0], [x2_0], color=:red, markershape=:circle, markersize=6, 
             label="Ponto Inicial ($x1_0, $x2_0)")
    
    return p
end

# =========================================================================
# Execução do Script
# =========================================================================
# 1. Instanciar o plano com as curvas e restrições ótimas
plot_final = plot_switching_curves()

# 2. Injetar as duas trajetórias parabólicas com restrição de estado
plot_example_curve(plot_final, (-1, -1))
plot_example_curve(plot_final, (1.5, 0))

# 3. Exibir gráfico consolidado
display(plot_final)
savefig(plot_final, "trajetorias_parabolicas.png")