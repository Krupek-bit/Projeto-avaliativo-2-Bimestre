@extends('layouts.app')
@section('titulo', 'Veículos')

@section('content')
<div class="d-flex flex-wrap gap-2 justify-content-between align-items-center mb-3">
  <h1 class="h3">Veículos</h1>
  <a href="{{ route('veiculos.create') }}" class="btn btn-primary">Novo veículo</a>
</div>

<div class="table-responsive">
  <table class="table table-striped table-hover bg-white align-middle">
    <thead>
      <tr><th>Placa</th><th>Marca / Modelo</th><th>Ano</th><th>Tipo</th><th>Status</th><th>Km atual</th><th class="text-end">Ações</th></tr>
    </thead>
    <tbody>
    @forelse($veiculos as $v)
      <tr>
        <td>{{ $v->placa }}</td>
        <td>{{ $v->marca }} {{ $v->modelo }}</td>
        <td>{{ $v->ano }}</td>
        <td>{{ $v->tipo }}</td>
        <td>
          <span class="badge text-bg-{{ match($v->status) {
              'ativo' => 'success', 'em_viagem' => 'primary', default => 'light' } }}">
            {{ ucfirst(str_replace('_', ' ', $v->status)) }}
          </span>
        </td>
        <td>{{ number_format($v->quilometragem_atual, 0, ',', '.') }} km</td>
        <td class="text-end text-nowrap">
          <a href="{{ route('veiculos.show', $v) }}" class="btn btn-sm btn-outline-secondary">Ver</a>
          <a href="{{ route('veiculos.edit', $v) }}" class="btn btn-sm btn-outline-primary">Editar</a>
          <form method="POST" action="{{ route('veiculos.destroy', $v) }}" class="d-inline"
                onsubmit="return confirm('Excluir este veículo?')">
            @csrf @method('DELETE')
            <button class="btn btn-sm btn-outline-danger">Excluir</button>
          </form>
        </td>
      </tr>
    @empty
      <tr><td colspan="7" class="text-center text-muted">Nenhum veículo cadastrado.</td></tr>
    @endforelse
    </tbody>
  </table>
</div>
{{ $veiculos->links('pagination::bootstrap-5') }}
@endsection