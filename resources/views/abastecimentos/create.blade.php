@extends('layouts.app')
@section('titulo', 'Novo abastecimento')

@section('content')
<h1 class="h3 mb-3">Novo abastecimento</h1>
<form method="POST" action="{{ route('abastecimentos.store') }}">
  @csrf
  @include('abastecimentos._form')
</form>
@endsection