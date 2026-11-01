@extends('layouts.app')
@section('titulo', 'Editar abastecimento')

@section('content')
<h1 class="h3 mb-3">Editar abastecimento</h1>
<form method="POST" action="{{ route('abastecimentos.update', $abastecimento) }}">
  @csrf
  @method('PUT')
  @include('abastecimentos._form')
</form>
@endsection