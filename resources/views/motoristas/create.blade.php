@extends('layouts.app')
@section('titulo', 'Novo motorista')

@section('content')
<h1 class="h3 mb-3">Novo motorista</h1>
<form method="POST" action="{{ route('motoristas.store') }}">
  @csrf
  @include('motoristas._form')
</form>
@endsection