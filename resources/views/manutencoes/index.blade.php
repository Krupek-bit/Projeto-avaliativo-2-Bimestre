@extends('layouts.app')
@section('titulo', 'Manutenções')

@section('content')
<div class="d-flex flex-wrap gap-2 justify-content-between align-items-center mb-3">
  <h1 class="h3 mb-0">Manutenções</h1>
  <a href="{{ route('manutencoes.create') }}" class="btn btn-primary">Nova manutenção</a>
</div>

<div class="table-responsive">
  <table class="table table-striped table-hover bg-white align-middle">
    <thead>
      <tr><th>Veículo</th><th>Data</th><th>Tipo</th><th>Oficina</th><th>Valor</th><th>Km</th><th class="text-end">Ações</th></tr>
    </thead>
    <tbody>
    @forelse($manutencoes as $m)
      <tr>
        <td>{{ $m->veiculo->placa ?? '-' }}</td>
        <td class="text-nowrap">{{ \Carbon\Carbon::parse($m->data_manutencao)->format('d/m/Y') }}</td>
        <td>{{ $m->tipo_manutencao }}</td>
        <td>{{ $m->oficina }}</td>
        <td class="text-nowrap">R$ {{ number_format($m->valor, 2, ',', '.') }}</td>
        <td>{{ number_format($m->quilometragem, 0, ',', '.') }}</td>
        <td class="text-end text-nowrap">
          <a href="{{ route('manutencoes.edit', $m) }}" class="btn btn-sm btn-outline-primary">Editar</a>
          <form method="POST" action="{{ route('manutencoes.destroy', $m) }}" class="d-inline"
                onsubmit="return confirm('Excluir esta manutenção?')">
            @csrf @method('DELETE')
            <button class="btn btn-sm btn-outline-danger">Excluir</button>
          </form>
        </td>
      </tr>
    @empty
      <tr><td colspan="7" class="text-center text-muted">Nenhuma manutenção cadastrada.</td></tr>
    @endforelse
    </tbody>
  </table>
</div>
{{ $manutencoes->links('pagination::bootstrap-5') }}
@endsection