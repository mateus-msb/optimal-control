using Plots

function plot_switching_curves(num_arcs=5)
    # Inicializa o construtor do gráfico com as configurações estéticas
    p = plot(title="Plano de Fase: Curva de Chaveamento Ótima",
             xlabel="x₁", ylabel="x₂",
             aspect_ratio=:equal,
             grid=:dot,
             legend=:outertopright,
             framestyle=:box,
             size=(800, 600),
             gridalpha=0.6,
             legendfontsize=10)
    
    odd_radii = [2 * i - 1 for i in 1:num_arcs]
    
    # 1. Traçar arcos do semiplano superior (x₂ >= 0) -> u = -1 (Centro em -1, 0)
    theta_upper = range(0, π, length=300)
    for (i, r) in enumerate(odd_radii)
        x1 = -1 .+ r .* cos.(theta_upper)
        x2 = r .* sin.(theta_upper)
        label = (i == 1) ? "Fronteira u = -1" : ""
        plot!(p, x1, x2, color=:blue, linewidth=2.5, label=label)
    end
    
    # 2. Traçar arcos do semiplano inferior (x₂ <= 0) -> u = +1 (Centro em 1, 0)
    theta_lower = range(π, 2π, length=300)
    for (i, r) in enumerate(odd_radii)
        x1 = 1 .+ r .* cos.(theta_lower)
        x2 = r .* sin.(theta_lower)
        label = (i == 1) ? "Fronteira u = +1" : ""
        plot!(p, x1, x2, color=:orange, linewidth=2.5, label=label)
    end
    
    hline!(p, [0], color=:black, linewidth=1.2, label="")
    vline!(p, [0], color=:black, linewidth=1.2, label="")
    
    scatter!(p, [1, -1], [0, 0], color=:purple, markershape=:xcross, markersize=8,
             label="Centros das Trajetórias (u = ±1)")
    scatter!(p, [0], [0], color=:green, markershape=:circle, markersize=7,
             label="Origem Alvo x(t_f)")
    
    limit = 2 * num_arcs
    xlims!(p, -limit, limit)
    ylims!(p, -limit, limit)

    return p
end 

function plot_example_curve(p, coord)
    x1_0, x2_0 = coord
        
    # CASO 1: Ponto (0, 2)
    if x1_0 == 0 && x2_0 == 2
        # Arco 1: u = -1, centro em (-1,0), raio sqrt(5). Vai de (0,2) até (1,-1)
        t1 = range(atan(2, 1), atan(-1, 2), length=150)
        plot!(p, -1 .+ sqrt(5).*cos.(t1), sqrt(5).*sin.(t1), color=:blue, linestyle=:dash, linewidth=2, label="Trajetória (0,2)")
        
        # Arco 2: u = +1, centro em (1,0), raio 1. Vai de (1,-1) até (0,0)
        t2 = range(-π/2, -π, length=100)
        plot!(p, 1 .+ 1.0.*cos.(t2), 1.0.*sin.(t2), color=:orange, linestyle=:dash, linewidth=2, label="")
        
    # CASO 2: Ponto (1, 1)
    elseif x1_0 == 1 && x2_0 == 1
        # Arco Único: u = +1, centro em (1,0), raio 1. Vai direto de (1,1) até (0,0)
        # Passa por (2,0) e (1,-1) no sentido horário
        t1 = range(π/2, -π, length=200)
        plot!(p, 1 .+ 1.0.*cos.(t1), 1.0.*sin.(t1), color=:orange, linestyle=:dash, linewidth=2, label="Trajetória (1,1)")
        
    # CASO 3: Ponto (-2, -2)
    elseif x1_0 == -2 && x2_0 == -2
        # Arco 1: u = +1, centro em (1,0), raio sqrt(13). Vai de (-2,-2) até (-1,3)
        # Ajuste de 2π para continuidade horária suave do ângulo no vetor de rotação
        t1 = range(atan(-2, -3) + 2π, atan(3, -2), length=150)
        plot!(p, 1 .+ sqrt(13).*cos.(t1), sqrt(13).*sin.(t1), color=:orange, linestyle=:dash, linewidth=2, label="Trajetória (-2,-2)")
        
        # Arco 2: u = -1, centro em (-1,0), raio 3. Desce de (-1,3) até (2,0) sobre o chaveamento Γ
        t2 = range(π/2, 0, length=100)
        plot!(p, -1 .+ 3.0.*cos.(t2), 3.0.*sin.(t2), color=:blue, linestyle=:dash, linewidth=2, label="")
        
        # Arco 3: u = +1, centro em (1,0), raio 1. Entra no arco final de (2,0) até (0,0)
        t3 = range(0, -π, length=100)
        plot!(p, 1 .+ 1.0.*cos.(t3), 1.0.*sin.(t3), color=:orange, linestyle=:dash, linewidth=2, label="")
        
    # CASO 4: Ponto (3, 0)
    elseif x1_0 == 3 && x2_0 == 0
        # Intersecção calculada analiticamente com a curva inferior r=3: (1.75, -2.9047)
        x1_int, x2_int = 1.75, -sqrt(8.4375)
        
        # Arco 1: u = -1, centro em (-1,0), raio 4. Vai de (3,0) até (1.75, -2.9047)
        t1 = range(0, atan(x2_int, x1_int - (-1)), length=150)
        plot!(p, -1 .+ 4.0.*cos.(t1), 4.0.*sin.(t1), color=:blue, linestyle=:dash, linewidth=2, label="Trajetória (3,0)")
        
        # Arco 2: u = +1, centro em (1,0), raio 3. Desce até o eixo x em (-2,0) sobre o chaveamento Γ
        t2 = range(atan(x2_int, x1_int - 1), -π, length=100)
        plot!(p, 1 .+ 3.0.*cos.(t2), 3.0.*sin.(t2), color=:orange, linestyle=:dash, linewidth=2, label="")
        
        # Arco 3: u = -1, centro em (-1,0), raio 1. Desce no arco final superior de (-2,0) até (0,0)
        t3 = range(π, 0, length=100)
        plot!(p, -1 .+ 1.0.*cos.(t3), 1.0.*sin.(t3), color=:blue, linestyle=:dash, linewidth=2, label="")
    end
    
    # Destaca e identifica o ponto inicial inserido
    scatter!(p, [x1_0], [x2_0], color=:red, speakershape=:circle, markersize=5, 
             label="Ponto Inicial ($x1_0, $x2_0)")
    
    return p
end

# =========================================================================
# Pipeline de Execução e Renderização Combinada
# =========================================================================
# 1. Instanciar a malha com as curvas ótimas (utilizando 4 arcos para visualização ampla)
plot_final = plot_switching_curves(2)

# 2. Injetar as quatro trajetórias de simulação calculadas
plot_example_curve(plot_final, (0, 2))
plot_example_curve(plot_final, (1, 1))
plot_example_curve(plot_final, (-2, -2))
plot_example_curve(plot_final, (3, 0))

# 3. Exibir e salvar o gráfico consolidado
display(plot_final)
savefig(plot_final, "chaveamentos_consolidados.png")