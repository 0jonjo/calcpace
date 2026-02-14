# Calcpace - Plano de Melhorias

Este documento descreve melhorias sugeridas para expandir as funcionalidades da gem Calcpace.

## 1. Conversões de Pace entre Unidades ✅ IMPLEMENTADO

**Prioridade:** Alta
**Complexidade:** Baixa
**Status:** ✅ Concluído em v1.8.0

### Descrição
Adicionar conversões diretas de pace entre quilômetros e milhas.

### Funcionalidades
- ✅ `pace_km_to_mi`: Converter pace/km para pace/milha
- ✅ `pace_mi_to_km`: Converter pace/milha para pace/km
- ✅ `convert_pace`: Método genérico de conversão

### Exemplo de Uso
```ruby
calc = Calcpace.new

# Se faço 5:00/km, qual seria o pace em milhas?
calc.convert_pace('05:00', :km_to_mi) # => "00:08:02" (5:00/km = 8:02/mi)
calc.convert_pace('08:00', :mi_to_km) # => "00:04:58" (8:00/mi ≈ 4:58/km)

# Métodos de conveniência
calc.pace_km_to_mi('05:00') # => "00:08:02"
calc.pace_mi_to_km('08:00') # => "00:04:58"
```

### Implementação
- ✅ Módulo `PaceConverter` criado
- ✅ Fator de conversão 1.60934 (km to mi) implementado
- ✅ Suporte para entrada em formato string (MM:SS) e numérico (segundos)
- ✅ 30+ testes criados e todos passando
- ✅ Documentação completa no README

---

## 2. Predições de Tempo entre Provas

**Prioridade:** Alta
**Complexidade:** Média

### Descrição
Estimar tempos em outras distâncias baseado em performance em uma prova, usando fórmulas reconhecidas.

### Fórmulas Sugeridas
- **Riegel**: `T2 = T1 * (D2/D1)^1.06`
- **Cameron**: Ajustes para ultra distâncias
- **Daniels**: Tabelas VDOT

### Exemplo de Uso
```ruby
calc = Calcpace.new

# Baseado em um 5K de 20:00, prever tempo de maratona
calc.predict_time(from_race: '5k', from_time: '00:20:00', to_race: 'marathon')
# => "03:05:23"

calc.predict_time(from_race: '10k', from_time: '00:42:00', to_race: 'half_marathon')
# => "01:31:45"

# Com múltiplas fórmulas
calc.predict_time('5k', '00:20:00', 'marathon', method: :riegel)
calc.predict_time('5k', '00:20:00', 'marathon', method: :daniels)
```

### Implementação
- Criar módulo `RacePredictor`
- Implementar fórmula de Riegel como padrão
- Adicionar opção para escolher método de predição
- Validar que distância de destino seja diferente da origem

---

## 3. Pace Splits para Provas ✅ IMPLEMENTADO

**Prioridade:** Alta
**Complexidade:** Baixa
**Status:** ✅ Concluído em v1.8.0

### Descrição
Calcular tempos parciais (splits) para uma prova baseado em tempo alvo.

### Exemplo de Uso
```ruby
calc = Calcpace.new

# Splits a cada 5K para meia maratona
calc.race_splits('half_marathon', target_time: '01:30:00', split_distance: '5k')
# => ["00:21:20", "00:42:40", "01:03:59", "01:25:19", "01:30:00"]

# Splits por quilômetro para 10K
calc.race_splits('10k', target_time: '00:40:00', split_distance: '1k')
# => ["00:04:00", "00:08:00", "00:12:00", ..., "00:40:00"]

# Splits em milhas
calc.race_splits('marathon', target_time: '03:30:00', split_distance: '1mile')
# => ["00:08:02", "00:16:04", ..., "03:30:00"]

# Negative splits (progressão - segunda metade mais rápida)
calc.race_splits('10k', target_time: '00:40:00', split_distance: '5k', strategy: :negative)
# => ["00:20:48", "00:40:00"]

# Positive splits (conservador - primeira metade mais rápida)
calc.race_splits('10k', target_time: '00:40:00', split_distance: '5k', strategy: :positive)
# => ["00:19:12", "00:40:00"]

# Even pace (pace constante - padrão)
calc.race_splits('marathon', target_time: '03:00:00', split_distance: '5k', strategy: :even)
```

### Implementação
- ✅ Módulo `RaceSplits` criado
- ✅ Estratégias suportadas: `:even` (constante), `:negative` (progressivo ~4%), `:positive` (conservador ~4%)
- ✅ Validação de `split_distance` implementada
- ✅ Retorna array de tempos acumulados
- ✅ Suporte para distâncias padrão ('5k', '1mile') e customizadas (números em km)
- ✅ 30+ testes criados e todos passando
- ✅ Documentação completa no README

---

## 4. Zonas de Treino (Training Zones)

**Prioridade:** Média
**Complexidade:** Média

### Descrição
Calcular zonas de intensidade de treino baseadas em tempos de prova ou VO2max.

### Zonas Sugeridas
- **Recovery/Easy**: 65-79% do ritmo de prova
- **Tempo/Threshold**: 88-92% do ritmo de prova
- **Interval/VO2max**: 95-100% do ritmo de prova
- **Repetition**: 102-105% do ritmo de prova

### Exemplo de Uso
```ruby
calc = Calcpace.new

# Baseado em tempo de maratona
calc.training_zones('marathon', '03:30:00')
# => {
#      easy: { min: "05:30", max: "06:00" },
#      tempo: { min: "04:45", max: "05:00" },
#      threshold: { min: "04:40", max: "04:50" },
#      interval: { min: "04:20", max: "04:30" },
#      repetition: { min: "04:10", max: "04:20" }
#    }

# Com formato detalhado
calc.training_zones('10k', '00:40:00', format: :detailed)
# => retorna com descrições e percentuais
```

### Implementação
- Criar módulo `TrainingZones`
- Usar percentuais de Jack Daniels ou Pete Pfitzinger
- Retornar faixas de pace para cada zona
- Opção de calcular por VO2max estimado

---

## 5. Comparação de Esforços entre Provas

**Prioridade:** Média
**Complexidade:** Média

### Descrição
Comparar performances em diferentes distâncias para avaliar consistência e pontos fortes.

### Exemplo de Uso
```ruby
calc = Calcpace.new

# Comparar 5K e 10K
calc.compare_efforts('5k', '00:20:00', '10k', '00:42:00')
# => {
#      effort_balance: "balanced",
#      equivalent_5k: "20:30",
#      equivalent_10k: "41:00",
#      stronger_at: "5k",
#      difference_pct: 2.5
#    }

# Comparar múltiplas provas
calc.compare_multiple({
  '5k' => '00:20:00',
  '10k' => '00:42:00',
  'half_marathon' => '01:32:00',
  'marathon' => '03:15:00'
})
# => análise de consistência e recomendações
```

### Implementação
- Usar predições para normalizar distâncias
- Calcular desvios entre tempo real e predito
- Identificar distâncias mais fortes/fracas
- Sugerir áreas de treino prioritárias

---

## 6. Pace Range (Trabalhar com Faixas)

**Prioridade:** Baixa
**Complexidade:** Baixa

### Descrição
Calcular tempos baseados em faixas de pace ao invés de valores únicos.

### Exemplo de Uso
```ruby
calc = Calcpace.new

# Calcular tempo com faixa de pace
calc.pace_range(from: '05:00', to: '05:30', distance: '10k')
# => { min_time: "00:50:00", max_time: "00:55:00", avg_time: "00:52:30" }

# Verificar se pace está dentro de uma zona alvo
calc.pace_in_range?('05:15', from: '05:00', to: '05:30')
# => true
```

### Implementação
- Estender métodos existentes para aceitar ranges
- Validar que `from` < `to`
- Retornar min, max e average

---

## 7. Ajustes para Elevação/Altitude

**Prioridade:** Baixa
**Complexidade:** Alta

### Descrição
Ajustar pace para compensar ganho/perda de elevação em percursos.

### Exemplo de Uso
```ruby
calc = Calcpace.new

# Ajustar pace para subida
calc.adjust_for_elevation('05:00', elevation_gain: 100, distance: 10)
# => "05:20" (pace ajustado para subida)

# Calcular equivalente em terreno plano
calc.flat_equivalent('05:30', elevation_gain: 200, distance: 10)
# => "05:00" (equivalente no plano)
```

### Implementação
- Usar regra aproximada: +10-12s por 100m de elevação
- Considerar fatores: gradiente, distância, condição física
- Referenciar estudos de fisiologia do exercício

---

## 8. Benchmarking e Age Grading

**Prioridade:** Baixa
**Complexidade:** Alta

### Descrição
Comparar performances com padrões de referência (recordes, age-grading, percentis).

### Exemplo de Uso
```ruby
calc = Calcpace.new

# Age grading
calc.age_grade('marathon', '03:30:00', age: 35, gender: 'M')
# => {
#      age_grade_pct: 72.5,
#      percentile: 85,
#      category: "Local Class",
#      world_record_equivalent: "02:08:30"
#    }

# Comparar com recordes
calc.compare_to_records('5k', '00:20:00')
# => {
#      world_record_diff: "+07:14",
#      national_record_diff: "+05:30",
#      percentile_global: 95
#    }
```

### Implementação
- Integrar tabelas WMA (World Masters Athletics)
- Manter base de recordes atualizados
- Calcular percentis baseados em distribuições estatísticas

---

## 9. Validações e Sugestões Inteligentes

**Prioridade:** Média
**Complexidade:** Baixa

### Descrição
Validar se valores são realistas e sugerir correções para inputs comuns.

### Funcionalidades
- Detectar paces muito rápidos ou lentos
- Sugerir correção de formato
- Alertar sobre predições irrealistas

### Exemplo de Uso
```ruby
calc = Calcpace.new

# Validar se pace é razoável
calc.validate_pace('01:00', '5k')
# => { valid: false, reason: "Too fast - world record is 12:35", suggestion: "Did you mean 05:00?" }

calc.validate_pace('15:00', 'marathon')
# => { valid: false, reason: "Too slow - consider walking pace", suggestion: nil }

# Correção automática
calc.auto_correct('500', context: :pace)
# => "05:00" (detectou que faltou ":" )
```

### Implementação
- Definir ranges razoáveis por distância
- Detectar padrões de erro comuns
- Oferecer sugestões quando possível

---

## 10. Formatos de Output Flexíveis

**Prioridade:** Baixa
**Complexidade:** Baixa

### Descrição
Permitir diferentes formatos de saída para melhor integração e usabilidade.

### Exemplo de Uso
```ruby
calc = Calcpace.new

# Formato curto (padrão)
calc.race_time_clock('05:00', 'marathon', format: :short)
# => "03:30:58"

# Formato verboso
calc.race_time_clock('05:00', 'marathon', format: :verbose)
# => "3 hours, 30 minutes, 58 seconds"

# Formato compacto
calc.race_time_clock('05:00', 'marathon', format: :compact)
# => "3h30m58s"

# JSON para APIs
calc.race_time('05:00', 'marathon', format: :json)
# => { hours: 3, minutes: 30, seconds: 58, total_seconds: 12658 }
```

### Implementação
- Adicionar parâmetro `format` opcional
- Criar métodos de formatação centralizados
- Manter retrocompatibilidade (padrão = comportamento atual)

---

## 11. Estimativa de Calorias

**Prioridade:** Baixa
**Complexidade:** Média

### Descrição
Estimar gasto calórico baseado em distância, tempo e peso do atleta.

### Exemplo de Uso
```ruby
calc = Calcpace.new

# Estimativa simples
calc.calories('10k', time: '00:45:00', weight_kg: 70)
# => 600

# Com mais parâmetros
calc.calories('marathon', time: '03:30:00', weight_kg: 70, age: 35, gender: 'M')
# => { total: 2800, per_km: 66, per_hour: 800 }
```

### Implementação
- Usar fórmulas padrão (MET, Compendium of Physical Activities)
- Considerar peso, intensidade, duração
- Opcionalmente: idade, gênero, frequência cardíaca

---

## Ordem de Implementação Sugerida

### Fase 1 - Essenciais (v1.8.0)
1. ✅ **Conversões de Pace** (mais comum, baixa complexidade)
2. ✅ **Pace Splits** (muito útil, baixa complexidade)
3. ✅ **Predições de Tempo** (alto valor, complexidade média)

### Fase 2 - Treino (v1.9.0)
4. **Zonas de Treino** (útil para treino estruturado)
5. **Comparação de Esforços** (análise de performance)
6. **Validações Inteligentes** (melhor UX)

### Fase 3 - Avançadas (v2.0.0)
7. **Pace Range** (flexibilidade)
8. **Formatos de Output** (integração)
9. **Benchmarking/Age Grading** (contextualização)

### Fase 4 - Extras (v2.1.0+)
10. **Ajustes de Elevação** (casos especiais)
11. **Estimativa de Calorias** (complementar)

---

## Considerações de Implementação

### Testes
- Cada nova feature deve ter cobertura de testes completa
- Incluir casos extremos e validações
- Manter cobertura > 95%

### Documentação
- Atualizar README.md com exemplos
- Adicionar RDoc para todos os métodos públicos
- Criar guias de uso para features complexas

### Retrocompatibilidade
- Não quebrar APIs existentes
- Usar parâmetros opcionais para novas funcionalidades
- Seguir versionamento semântico

### Performance
- Evitar cálculos redundantes
- Cachear valores quando apropriado
- Manter tempo de resposta < 10ms para operações simples

---

## Referências

- **Jack Daniels' Running Formula** - Training zones e VDOT
- **Pete Riegel Formula** - Race predictions
- **WMA Age Grading Tables** - Age-adjusted performance
- **Compendium of Physical Activities** - Calorie estimation
- **Running Science** (Owen Anderson) - Physiological adaptations
