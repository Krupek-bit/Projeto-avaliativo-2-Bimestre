@extends('layouts.app')
@section('titulo', 'Motoristas')

@section('content')
<div class="d-flex flex-wrap gap-2 justify-content-between align-items-center mb-3">
  <h1 class="h3 mb-0">Motoristas</h1>
  <a href="{{ route('motoristas.create') }}" class="btn btn-primary">Novo motorista</a>
</div>

<div class="table-responsive">
  <table class="table table-striped table-hover bg-white align-middle">
    <thead>
      <tr><th>Nome</th><th>CNH</th><th>Categoria</th><th>Telefone</th><th>Validade CNH</th><th>Status</th><th class="text-end">Ações</th></tr>
    </thead>
    <tbody>
    @forelse($motoristas as $m)
      <tr>
        <td>{{ $m->nome }}</td>
        <td>{{ $m->cnh }}</td>
        <td>{{ $m->categoria_cnh }}</td>
        <td>{{ $m->telefone }}</td>
        <td class="text-nowrap {{ \Carbon\Carbon::parse($m->validade_cnh)->isPast() ? 'text-danger fw-bold' : '' }}">
          {{ \Carbon\Carbon::parse($m->validade_cnh)->format('d/m/Y') }}
        </td>
        <td>
          <span class="badge text-bg-{{ $m->status === 'ativo' ? 'success' : 'secondary' }}">
            {{ ucfirst($m->status) }}
          </span>
        </td>
        <td class="text-end text-nowrap">
          <a href="{{ route('motoristas.show', $m) }}" class="btn btn-sm btn-outline-secondary">Ver</a>
          <a href="{{ route('motoristas.edit', $m) }}" class="btn btn-sm btn-outline-primary">Editar</a>
          <form method="POST" action="{{ route('motoristas.destroy', $m) }}" class="d-inline"
                onsubmit="return confirm('Excluir este motorista?')">
            @csrf @method('DELETE')
            <button class="btn btn-sm btn-outline-danger">Excluir</button>
          </form>
        </td>
      </tr>
    @empty
      <tr><td colspan="7" class="text-center text-muted">Nenhum motorista cadastrado.</td></tr>
    @endforelse
    </tbody>
  </table>
</div>
{{ $motoristas->links('pagination::bootstrap-5') }}
@endsection