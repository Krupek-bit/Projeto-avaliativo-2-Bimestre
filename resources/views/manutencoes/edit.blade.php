@extends('layouts.app')
@section('titulo', 'Editar manutenção')

@section('content')
<h1 class="h3 mb-3">Editar manutenção</h1>
<form method="POST" action="{{ route('manutencoes.update', $manutencao) }}">
  @csrf
  @method('PUT')
  @include('manutencoes._form')
</form>
@endsection