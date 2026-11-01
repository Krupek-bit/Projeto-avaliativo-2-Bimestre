@extends('layouts.app')
@section('titulo', $motorista->nome)

@section('content')
<div class="card mb-4">
  <div class="card-body">
    <h1 class="h4">{{ $motorista->nome }}</h1>
    <div class="row g-2 mt-2">
      <div class="col-12 col-sm-6 col-md-3"><strong>CNH:</strong> {{ $motorista->cnh }}</div>
      <div class="col-12 col-sm-6 col-md-3"><strong>Categoria:</strong> {{ $motorista->categoria_cnh }}</div>
      <div class="col-12 col-sm-6 col-md-3"><strong>Telefone:</strong> {{ $motorista->telefone }}</div>
      <div class="col-12 col-sm-6 col-md-3"><strong>Status:</strong> {{ ucfirst($motorista->status) }}</div>
      <div class="col-12 col-sm-6 col-md-3"><strong>Admissão:</strong> {{ \Carbon\Carbon::parse($motorista->data_admissao)->format('d/m/Y') }}</div>
      <div class="col-12 col-sm-6 col-md-3">
        <strong>Validade da CNH:</strong>
        <span class="{{ \Carbon\Carbon::parse($motorista->validade_cnh)->isPast() ? 'text-danger fw-bold' : '' }}">
          {{ \Carbon\Carbon::parse($motorista->validade_cnh)->format('d/m/Y') }}
        </span>
      </div>
    </div>
  </div>
</div>

<a href="{{ route('motoristas.index') }}" class="btn btn-secondary">Voltar</a>
@endsection