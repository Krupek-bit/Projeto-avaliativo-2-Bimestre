@extends('layouts.app')
@section('titulo', 'Início')

@section('content')
@php
  $resumo = [
    ['Veículos ativos', $veiculosAtivos, 'success'],
    ['Veículos em viagem', $veiculosEmViagem, 'primary'],
    ['Motoristas', $motoristas, 'secondary'],
    ['Viagens em andamento', $viagensAndamento, 'warning'],
  ];
  $modulos = [
    ['Veículos', 'Cadastro e consulta da frota', 'veiculos.index'],
    ['Motoristas', 'Dados e validade das CNHs', 'motoristas.index'],
    ['Viagens', 'Iniciar e finalizar viagens', 'viagens.index'],
    ['Abastecimentos', 'Registro de combustível', 'abastecimentos.index'],
    ['Manutenções', 'Controle de manutenções', 'manutencoes.index'],
    ['Despesas', 'Pedágios, multas e outros gastos', 'despesas.index'],
    ['Hodômetros', 'Leituras de quilometragem', 'hodometros.index'],
  ];
@endphp

<div class="mb-4">
  <h1 class="h3 mb-1">Olá, {{ session('usuario_nome') }}</h1>
  <p class="text-muted mb-0">Resumo da frota e acesso rápido aos módulos.</p>
</div>

<div class="row g-3 mb-4">
  @foreach($resumo as [$rotulo, $valor, $cor])
    <div class="col-6 col-lg-3">
      <div class="card border-0 border-start border-4 border-{{ $cor }} shadow-sm h-100">
        <div class="card-body">
          <div class="text-muted small">{{ $rotulo }}</div>
          <div class="display-6 fw-bold">{{ $valor }}</div>
        </div>
      </div>
    </div>
  @endforeach
</div>

<h2 class="h5 mb-3">Módulos</h2>
<div class="row g-3">
  @foreach($modulos as [$titulo, $descricao, $rota])
    <div class="col-12 col-sm-6 col-lg-4">
      <div class="card shadow-sm h-100">
        <div class="card-body">
          <h3 class="h6 mb-1">{{ $titulo }}</h3>
          <p class="text-muted small mb-3">{{ $descricao }}</p>
          <a href="{{ route($rota) }}" class="btn btn-sm btn-outline-primary stretched-link">Abrir</a>
        </div>
      </div>
    </div>
  @endforeach
</div>
@endsection