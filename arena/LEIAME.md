# Arena (protótipo)

Quatro lutadores numa arena com uma zona segura que vai fechando. Armas e itens aparecem pelo chão; o último sobrevivente vence.

Feito em **Godot 4.4** (funciona em 4.4 ou mais recente).

## Como abrir

1. Abra a Godot e clique em **Importar**.
2. Selecione o arquivo `arena/project.godot` deste repositório.
3. Aperte **F5** (ou o botão ▶) para jogar.

## Controles

| Ação | Tecla |
|---|---|
| Mover | WASD ou setas |
| Mirar | Mouse |
| Atacar | Clique esquerdo ou Espaço |
| Pegar / trocar item | E |
| Reiniciar partida | R |

Você é o **Amarelo** (marcado com uma setinha). Os outros três são bots.
As teclas podem ser mudadas em *Projeto → Configurações do Projeto → Mapa de Entrada*.

## Regras do protótipo

- Todos começam com **100 de vida** e de **mãos vazias** (soco).
- Encostar num item pega ele automaticamente quando você está de mãos vazias. Para **trocar** de arma, aperte **E** perto do item. A arma antiga cai no chão.
- **Espada**: corpo a corpo, uso infinito.
- **Arco**: atira flechas, 10 flechas.
- **Granada**: arremessa até onde o mouse aponta, explode em área (cuidado, ela também te acerta), 3 usos.
- **Cura (+)**: recupera 35 de vida.
- A **zona** fecha em 5 fases. Fora dela você toma dano, e o dano aumenta a cada fase.
- Novos itens aparecem dentro da zona a cada 6 segundos.

## Onde mexer

| Quero mudar... | Arquivo |
|---|---|
| Dano, alcance, munição, frequência dos itens | `scripts/weapons.gd` |
| Tempo e tamanho das fases da zona | `scripts/zone.gd` (`PHASES`) |
| Velocidade e vida dos lutadores | `scripts/fighter.gd` (ou no Inspetor da cena `scenes/fighter.tscn`) |
| Comportamento dos bots | `scripts/bot.gd` |
| Formato da arena e obstáculos | `scripts/arena.gd` (`BOUNDS`, `OBSTACLES`) |
| Itens iniciais, nomes e cores dos lutadores | `scripts/main.gd` |
| Textos da tela | `scripts/hud.gd` e os nós dentro de `HUD` em `scenes/main.tscn` |

## Modo espectador e teste automático

Para ver só os 4 bots lutando, rode pelo terminal:

```
godot --path arena -- --espectador
```

Para simular uma partida sem janela e ver quem venceu:

```
godot --headless --path arena --fixed-fps 60 -- --espectador --teste
```

## Estrutura

```
arena/
├── project.godot
├── assets/sprites/   # sprites originais (lutadores, armas, cura)
├── scenes/           # main, fighter, pickup, arrow, grenade
└── scripts/          # lógica do jogo
```
