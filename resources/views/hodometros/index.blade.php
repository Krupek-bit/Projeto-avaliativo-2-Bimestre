@extends('layouts.app')

@section('titulo', 'Hodômetros')

@section('content')
<div class="d-flex flex-wrap gap-2 justify-content-between align-items-center mb-3">
  <h1 class="h3 mb-0">Histórico de hodômetros</h1>
  <a href="{{ route('hodometros.create') }}" class="btn btn-primary">Registrar quilometragem</a>
</div>

<div class="table-responsive">
  <table class="table table-striped table-hover bg-white align-middle">
    <thead>
      <tr>
        <th>Veículo</th>
        <th>Data</th>
        <th>Quilometragem</th>
        <th>Observação</th>
      </tr>
    </thead>
    <tbody>
    @forelse($hodometros as $hodometro)
      <tr>
        <td>{{ $hodometro->veiculo->placa ?? '-' }}</td>
        <td class="text-nowrap">{{ $hodometro->data_registro->format('d/m/Y') }}</td>
        <td>{{ number_format($hodometro->quilometragem, 0, ',', '.') }} km</td>
        <td>{{ $hodometro->observacao ?: '-' }}</td>
      </tr>
    @empty
      <tr><td colspan="4" class="text-center text-muted">Nenhum registro de quilometragem.</td></tr>
    @endforelse
    </tbody>
  </table>
</div>

{{ $hodometros->links('pagination::bootstrap-5') }}
@endsection
