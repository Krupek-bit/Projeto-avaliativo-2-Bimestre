@extends('layouts.app')
@section('titulo', 'Viagem')

@section('content')
<div class="card mb-4">
  <div class="card-body">
    <h1 class="h4">Viagem para {{ $viagem->destino }}</h1>
    <div class="row g-2 mt-2">
      <div class="col-12 col-sm-6 col-md-4"><strong>Veículo:</strong> {{ $viagem->veiculo->placa ?? '-' }}</div>
      <div class="col-12 col-sm-6 col-md-4"><strong>Motorista:</strong> {{ $viagem->motorista->nome ?? '-' }}</div>
      <div class="col-12 col-sm-6 col-md-4"><strong>Finalidade:</strong> {{ $viagem->finalidade }}</div>
      <div class="col-12 col-sm-6 col-md-4"><strong>Saída:</strong> {{ $viagem->data_saida?->format('d/m/Y H:i') }}</div>
      <div class="col-12 col-sm-6 col-md-4"><strong>Retorno:</strong> {{ $viagem->data_retorno?->format('d/m/Y H:i') ?? 'Em andamento' }}</div>
      <div class="col-12 col-sm-6 col-md-4"><strong>Km:</strong> {{ $viagem->km_inicial }} → {{ $viagem->km_final ?? '-' }}</div>
    </div>
  </div>
</div>

<a href="{{ route('viagens.index') }}" class="btn btn-secondary">Voltar</a>
@endsection