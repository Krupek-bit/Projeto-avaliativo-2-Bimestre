@extends('layouts.app')
@section('titulo', 'Viagens')

@section('content')
<div class="d-flex flex-wrap gap-2 justify-content-between align-items-center mb-3">
  <h1 class="h3 mb-0">Viagens</h1>
  <a href="{{ route('viagens.create') }}" class="btn btn-primary">Nova viagem</a>
</div>

<div class="table-responsive">
  <table class="table table-striped table-hover bg-white align-middle">
    <thead>
      <tr><th>Veículo</th><th>Motorista</th><th>Destino</th><th>Saída</th><th>Retorno</th><th>Km</th><th class="text-end">Ações</th></tr>
    </thead>
    <tbody>
    @forelse($viagens as $v)
      <tr>
        <td>{{ $v->veiculo->placa ?? '-' }}</td>
        <td>{{ $v->motorista->nome ?? '-' }}</td>
        <td>{{ $v->destino }}</td>
        <td>{{ $v->data_saida?->format('d/m/Y H:i') }}</td>
        <td>
          @if($v->data_retorno)
            {{ $v->data_retorno->format('d/m/Y H:i') }}
          @else
            <span class="badge text-bg-primary">Em andamento</span>
          @endif
        </td>
        <td>{{ $v->km_inicial }} → {{ $v->km_final ?? '-' }}</td>
        <td class="text-end text-nowrap">
          <a href="{{ route('viagens.show', $v) }}" class="btn btn-sm btn-outline-secondary">Ver</a>
          <a href="{{ route('viagens.edit', $v) }}" class="btn btn-sm btn-outline-primary">Editar</a>
          <form method="POST" action="{{ route('viagens.destroy', $v) }}" class="d-inline"
                onsubmit="return confirm('Excluir esta viagem?')">
            @csrf @method('DELETE')
            <button class="btn btn-sm btn-outline-danger">Excluir</button>
          </form>
        </td>
      </tr>
    @empty
      <tr><td colspan="7" class="text-center text-muted">Nenhuma viagem cadastrada.</td></tr>
    @endforelse
    </tbody>
  </table>
</div>
{{ $viagens->links('pagination::bootstrap-5') }}
@endsection