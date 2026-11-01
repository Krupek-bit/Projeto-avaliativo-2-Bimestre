@extends('layouts.app')
@section('titulo', $veiculo->placa)

@section('content')
<div class="card mb-4">
  <div class="card-body">
    <h1 class="h4">{{ $veiculo->marca }} {{ $veiculo->modelo }} <small class="text-muted">({{ $veiculo->placa }})</small></h1>
    <div class="row">
      <div class="col-md-3"><strong>Ano:</strong> {{ $veiculo->ano }}</div>
      <div class="col-md-3"><strong>Tipo:</strong> {{ $veiculo->tipo }}</div>
      <div class="col-md-3"><strong>Capacidade:</strong> {{ $veiculo->capacidade }}</div>
      <div class="col-md-3"><strong>Status:</strong> {{ ucfirst(str_replace('_', ' ', $veiculo->status)) }}</div>
    </div>
    <p class="mt-2 mb-0"><strong>Quilometragem:</strong> {{ number_format($veiculo->quilometragem_atual, 0, ',', '.') }} km</p>
  </div>
</div>

<h2 class="h5">Abastecimentos</h2>
<div class="table-responsive">
  <table class="table table-sm bg-white">
    <thead><tr><th>Data</th><th>Combustível</th><th>Litros</th><th>Total</th><th>Km</th></tr></thead>
    <tbody>
    @forelse($veiculo->abastecimentos as $a)
      <tr>
        <td>{{ \Carbon\Carbon::parse($a->data_abastecimento)->format('d/m/Y') }}</td>
        <td>{{ $a->tipo_combustivel }}</td>
        <td>{{ $a->litros }}</td>
        <td>R$ {{ number_format($a->valor_total, 2, ',', '.') }}</td>
        <td>{{ $a->quilometragem }}</td>
      </tr>
    @empty
      <tr><td colspan="5" class="text-muted text-center">Sem abastecimentos.</td></tr>
    @endforelse
    </tbody>
  </table>
</div>

<h2 class="h5 mt-4">Manutenções</h2>
<div class="table-responsive">
  <table class="table table-sm bg-white">
    <thead><tr><th>Data</th><th>Tipo</th><th>Oficina</th><th>Valor</th></tr></thead>
    <tbody>
    @forelse($veiculo->manutencoes as $m)
      <tr>
        <td>{{ \Carbon\Carbon::parse($m->data_manutencao)->format('d/m/Y') }}</td>
        <td>{{ $m->tipo_manutencao }}</td>
        <td>{{ $m->oficina }}</td>
        <td>R$ {{ number_format($m->valor, 2, ',', '.') }}</td>
      </tr>
    @empty
      <tr><td colspan="4" class="text-muted text-center">Sem manutenções.</td></tr>
    @endforelse
    </tbody>
  </table>
</div>

<a href="{{ route('veiculos.index') }}" class="btn btn-secondary">Voltar</a>
@endsection