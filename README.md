# CALCPACE

### [PT-BR]

Um projeto de estudo de TDD em Ruby baseado em outro projeto meu, o [Calcpace (originalmente em Python)](https://github.com/0jonjo/calcpace-py). Ele calcula o pace de corrida, o tempo de corrida ou a distância a partir de dados inseridos pelo usuário.

## Instalação

### Clone o repositório

```shell
git clone git@github.com:0jonjo/calcpace.git
cd calcpace
```

### Instale as dependências

Usando [Bundler](https://github.com/bundler/bundler)

```shell
bundle install
```

## Use a calculadora

Chamar main.rb informe a opção de cálculo e os dados da corrida. 

Utilize p para calcular o pace e informe o tempo de corrida (HH:MM:SS) e a distância (X.X) em quilômetros. 

```shell
ruby lib/main.rb p 01:00:00 10
```
```shell
You ran 10.0 km in 01:00:00 at 00:06:00 pace.
```

Utilize t para calcular o tempo de corrida e informe o pace (HH:MM:SS) e a distância (X.X) em quilômetros. 

```shell
ruby lib/main.rb t 00:05:00 12
```
```shell
You ran 12.0 km in 01:00:00 at 00:05:00 pace.
```

Utilize d para calcular o tempo de corrida e informe o tempo de corrida (HH:MM:SS) e pace (HH:MM:SS). 

```shell
ruby lib/main.rb d 01:30:00 00:05:00
```
```shell
You ran 18.0 km in 01:30:00 at 00:05:00 pace.
```

Caso alguns dos parâmetros não esteja no padrão que o programa utiliza ele informa qual o problema em um erro (em inglês). 

### [EN]

A TDD Ruby study project to calculate the running pace, the predicted running time or distance. It's based on my original [Python Calcpace](https://github.com/0jonjo/calcpace-py).

## Install

### Clone the repository

```shell
git clone git@github.com:0jonjo/ruby-calcpace.git
cd ruby-calcpace
```

### Install dependencies

Using [Bundler](https://github.com/bundler/bundler)

```shell
bundle install
```

## Use the calculator

Use main.rb informs the calculation option and the running (jogging) data. 

Choose p to calculate pace and enter running time (HH:MM:SS) and distance (X.X) in kilometers.

```shell
ruby lib/main.rb p 01:00:00 10
```
```shell
You ran 10.0 km in 01:00:00 at 00:06:00 pace.
```

Choose t to calculate running time and enter pace  (HH:MM:SS) and distance (X.X) in kilometers.

```shell
ruby lib/main.rb t 00:05:00 12
```
```shell
You ran 12.0 km in 01:00:00 at 00:05:00 pace.

Choose d to calculate distance in kilometers and enter running time (HH:MM:SS) and pace (HH:MM:SS).

```shell
ruby lib/main.rb d 01:30:00 00:05:00
```
```shell
You ran 18.0 km in 01:30:00 at 00:05:00 pace.
```

If some of the parameters are not in the standard that the program uses, it informs what the problem is in an error.
