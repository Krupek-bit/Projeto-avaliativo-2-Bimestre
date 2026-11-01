@extends('layouts.app')
@section('titulo', 'Abastecimentos')

@section('content')
<div class="d-flex flex-wrap gap-2 justify-content-between align-items-center mb-3">
  <h1 class="h3 mb-0">Abastecimentos</h1>
  <a href="{{ route('abastecimentos.create') }}" class="btn btn-primary">Novo abastecimento</a>
</div>

<div class="table-responsive">
  <table class="table table-striped table-hover bg-white align-middle">
    <thead>
      <tr><th>Veículo</th><th>Data</th><th>Combustível</th><th>Litros</th><th>Valor/litro</th><th>Total</th><th>Km</th><th class="text-end">Ações</th></tr>
    </thead>
    <tbody>
    @forelse($abastecimentos as $a)
      <tr>
        <td>{{ $a->veiculo->placa ?? '-' }}</td>
        <td class="text-nowrap">{{ \Carbon\Carbon::parse($a->data_abastecimento)->format('d/m/Y') }}</td>
        <td>{{ $a->tipo_combustivel }}</td>
        <td>{{ number_format($a->litros, 2, ',', '.') }}</td>
        <td class="text-nowrap">R$ {{ number_format($a->valor_litro, 2, ',', '.') }}</td>
        <td class="text-nowrap">R$ {{ number_format($a->valor_total, 2, ',', '.') }}</td>
        <td>{{ number_format($a->quilometragem, 0, ',', '.') }}</td>
        <td class="text-end text-nowrap">
          <a href="{{ route('abastecimentos.edit', $a) }}" class="btn btn-sm btn-outline-primary">Editar</a>
          <form method="POST" action="{{ route('abastecimentos.destroy', $a) }}" class="d-inline"
                onsubmit="return confirm('Excluir este abastecimento?')">
            @csrf @method('DELETE')
            <button class="btn btn-sm btn-outline-danger">Excluir</button>
          </form>
        </td>
      </tr>
    @empty
      <tr><td colspan="8" class="text-center text-muted">Nenhum abastecimento cadastrado.</td></tr>
    @endforelse
    </tbody>
  </table>
</div>
{{ $abastecimentos->links('pagination::bootstrap-5') }}
@endsection