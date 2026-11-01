@extends('layouts.app')
@section('titulo', 'Despesas')

@section('content')
<div class="d-flex flex-wrap gap-2 justify-content-between align-items-center mb-3">
  <h1 class="h3 mb-0">Despesas</h1>
  <a href="{{ route('despesas.create') }}" class="btn btn-primary">Nova despesa</a>
</div>

<div class="table-responsive">
  <table class="table table-striped table-hover bg-white align-middle">
    <thead>
      <tr><th>Veículo</th><th>Data</th><th>Tipo</th><th>Descrição</th><th>Valor</th><th class="text-end">Ações</th></tr>
    </thead>
    <tbody>
    @forelse($despesas as $d)
      <tr>
        <td>{{ $d->veiculo->placa ?? '-' }}</td>
        <td class="text-nowrap">{{ \Carbon\Carbon::parse($d->data_despesa)->format('d/m/Y') }}</td>
        <td>{{ $d->tipo_despesa }}</td>
        <td>{{ $d->descricao }}</td>
        <td class="text-nowrap">R$ {{ number_format($d->valor, 2, ',', '.') }}</td>
        <td class="text-end text-nowrap">
          <a href="{{ route('despesas.edit', $d) }}" class="btn btn-sm btn-outline-primary">Editar</a>
          <form method="POST" action="{{ route('despesas.destroy', $d) }}" class="d-inline"
                onsubmit="return confirm('Excluir esta despesa?')">
            @csrf @method('DELETE')
            <button class="btn btn-sm btn-outline-danger">Excluir</button>
          </form>
        </td>
      </tr>
    @empty
      <tr><td colspan="6" class="text-center text-muted">Nenhuma despesa cadastrada.</td></tr>
    @endforelse
    </tbody>
  </table>
</div>
{{ $despesas->links('pagination::bootstrap-5') }}
@endsection