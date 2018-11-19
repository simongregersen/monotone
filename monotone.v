From iris.algebra Require Export cmra.
From iris.base_logic Require Import base_logic.
Local Arguments validN _ _ _ !_ /.
Local Arguments valid _ _  !_ /.
Local Arguments op _ _ _ !_ /.
Local Arguments pcore _ _ !_ /.

Record monotone {A : Type} (R : relation A) `{!PreOrder R} : Type := {
  monotone_car : list A;
  monotone_not_nil : bool_decide (monotone_car = []) = false
}.
Arguments monotone_car {_ _ _} _.
Arguments monotone_not_nil {_ _ _} _.
Local Coercion monotone_car : monotone >-> list.

Definition principal {A : Type} (R : relation A) `{!PreOrder R} (a : A) :
  monotone R :=
  {| monotone_car := [a]; monotone_not_nil := eq_refl |}.

Lemma monotone_eq `(R : relation A) `{!PreOrder R} (x y : monotone R) :
  monotone_car x = monotone_car y → x = y.
Proof.
  destruct x as [a ?], y as [b ?]; simpl.
  intros ->; f_equal. apply (proof_irrel _).
Qed.

Class ProperPreOrder {A : Type} `{Dist A} (R : relation A) := {
  ProperPreOrder_preorder :> PreOrder R;
  ProperPreOrder_ne :> ∀ n, Proper ((dist n) ==> (dist n) ==> iff) R
}.

Section monotone.
Local Set Default Proof Using "Type".
Context {A : ofeT} {R : relation A} `{!ProperPreOrder R}.
Implicit Types a b : A.
Implicit Types x y : monotone R.

(* OFE *)
Instance monotone_dist : Dist (monotone R) :=
  λ n x y, ∀ a, (∃ b, b ∈ (monotone_car x) ∧ R a b)
                  ↔ (∃ b, b ∈ (monotone_car y) ∧ R a b).

Instance monotone_equiv : Equiv (monotone R) := λ x y, ∀ n, x ≡{n}≡ y.

Definition monotone_ofe_mixin : OfeMixin (monotone R).
Proof.
  split.
  - rewrite /equiv /monotone_equiv /dist /monotone_dist; intuition auto using O.
  - intros n; split.
    + rewrite /dist /monotone_dist /equiv /monotone_equiv; intuition.
    + rewrite /dist /monotone_dist /equiv /monotone_equiv; intros ? ? Heq a.
      split; apply Heq.
    + rewrite /dist /monotone_dist /equiv /monotone_equiv;
        intros ? ? ? Heq Heq' a.
      split; intros Hxy.
      * apply Heq'; apply Heq; auto.
      * apply Heq; apply Heq'; auto.
  - intros n x y; rewrite /dist /monotone_dist; auto.
Qed.
Canonical Structure monotoneC := OfeT (monotone R) monotone_ofe_mixin.

(* CMRA *)
Instance monotone_validN : ValidN (monotone R) := λ n x, True.
Instance monotone_valid : Valid (monotone R) := λ x, True.

Program Instance monotone_op : Op (monotone R) := λ x y,
  {| monotone_car := monotone_car x ++ monotone_car y |}.
Next Obligation. by intros [[|??]] y. Qed.
Instance monotone_pcore : PCore (monotone R) := Some.

Instance monotone_comm : Comm (≡) (@op (monotone R) _).
Proof. intros x y n a; setoid_rewrite elem_of_app; split=> Ha; firstorder. Qed.
Instance monotone_assoc : Assoc (≡) (@op (monotone R) _).
Proof.
  intros x y z n a; simpl; repeat setoid_rewrite elem_of_app; split=> Ha; firstorder.
Qed.
Lemma monotone_idemp (x : monotone R) : x ⋅ x ≡ x.
Proof. intros n a; setoid_rewrite elem_of_app; split=> Ha; firstorder. Qed.

Instance monotone_validN_ne n :
  Proper (dist n ==> impl) (@validN (monotone R) _ n).
Proof. intros x y ?; rewrite /impl; auto. Qed.
Instance monotone_validN_proper n : Proper (equiv ==> iff) (@validN (monotone R) _ n).
Proof. move=> x y /equiv_dist H; auto. Qed.

Instance monotone_op_ne' x : NonExpansive (op x).
Proof.
  intros n y1 y2; rewrite /dist /monotone_dist /equiv /monotone_equiv.
  rewrite /=; setoid_rewrite elem_of_app => Heq a.
  specialize (Heq a); destruct Heq as [Heq1 Heq2].
  split; intros [b [[Hb|Hb] HRb]]; eauto.
  - destruct Heq1 as [? [? ?]]; eauto.
  - destruct Heq2 as [? [? ?]]; eauto.
Qed.
Instance monotone_op_ne : NonExpansive2 (@op (monotone R) _).
Proof. by intros n x1 x2 Hx y1 y2 Hy; rewrite Hy !(comm _ _ y2) Hx. Qed.
Instance monotone_op_proper : Proper ((≡) ==> (≡) ==> (≡)) op := ne_proper_2 _.

Lemma monotone_included (x y : monotone R) : x ≼ y ↔ y ≡ x ⋅ y.
Proof.
  split; [|by intros ?; exists y].
  by intros [z Hz]; rewrite Hz assoc monotone_idemp.
Qed.

Definition monotone_cmra_mixin : CmraMixin (monotone R).
Proof.
  apply cmra_total_mixin; try apply _ || by eauto.
  - intros ?; apply monotone_idemp.
  - rewrite /equiv /monotone_equiv /dist /monotone_dist; eauto.
Qed.
Canonical Structure monotoneR : cmraT := CmraT (monotone R) monotone_cmra_mixin.

Global Instance monotone_cmra_total : CmraTotal monotoneR.
Proof. rewrite /CmraTotal; eauto. Qed.
Global Instance monotone_core_id (x : monotone R) : CoreId x.
Proof. by constructor. Qed.

Global Instance monotone_cmra_discrete : CmraDiscrete monotoneR.
Proof.
  split; auto;
    rewrite /OfeDiscrete /Discrete
            /equiv /ofe_equiv /= /cmra_equiv /= /monotone_equiv
            /dist /monotone_dist; eauto.
Qed.

Global Instance principal_ne : NonExpansive (principal R).
Proof.
  rewrite /principal /= => n a1 a2 Ha; split; simpl;
    setoid_rewrite elem_of_list_singleton; intros [x [Hx HR]]; subst;
    eexists; (split; first eauto).
  - symmetry in Ha; eapply ProperPreOrder_ne; eauto.
  - eapply ProperPreOrder_ne; eauto.
Qed.

Global Instance principal_proper : Proper ((≡) ==> (≡)) (principal R) :=
  ne_proper _.

Global Instance principal_discrete a : Discrete (principal R a).
Proof.
  intros y; rewrite /dist /ofe_dist /= /equiv /ofe_equiv /= /monotone_equiv;
    eauto.
Qed.

Global Instance principal_injN_general n :
  Inj (λ a b, R a b ∧ R b a) (dist n) (principal R).
Proof.
  intros x y; rewrite /principal /dist /monotone_dist => Hxy; split.
  - destruct (Hxy x) as [Hx _]; edestruct Hx as [? [?%elem_of_list_singleton ?]];
    subst; eauto.
    { eexists _; split; first apply elem_of_list_singleton; eauto. reflexivity. }
  - destruct (Hxy y) as [_ Hy]; edestruct Hy as [? [?%elem_of_list_singleton ?]];
    subst; eauto.
    { eexists _; split; first apply elem_of_list_singleton; eauto. reflexivity. }
Qed.

Global Instance principal_injN {Has : AntiSymm (≡) R} n :
  Inj (dist n) (dist n) (principal R).
Proof.
  intros x y [Hxy Hyx]%principal_injN_general.
  erewrite (@anti_symm _ _ _ Has); eauto.
Qed.
Global Instance principal_inj `{!AntiSymm (≡) R} : Inj (≡) (≡) (principal R).
Proof. intros a b ?. apply equiv_dist=>n. by apply principal_injN, equiv_dist. Qed.

Lemma principal_included a b : principal R a ≼ principal R b ↔ R a b.
Proof.
  split.
  - intros [x Hx]. destruct (Hx 0 a) as [_ Hab].
    edestruct Hab as [c [?%elem_of_list_singleton ?]]; subst; eauto.
    { exists a; split; rewrite /=; eauto using elem_of_list_here; reflexivity. }
  - intros Hab. exists (principal R b); rewrite /= /monotone_op /=.
    intros ? z; split; simpl; setoid_rewrite elem_of_list_singleton;
      setoid_rewrite elem_of_cons; setoid_rewrite elem_of_list_singleton;
    intros [? Hab']; try destruct Hab'; simplify_eq; eauto.
    intuition subst; eauto. eexists; split; eauto. etrans; eauto.
Qed.

(** Internalized properties *)
Lemma monotone_equivI `{!AntiSymm (≡) R} {M} a b :
  principal R a ≡ principal R b ⊣⊢ (a ≡ b : uPred M).
Proof.
  uPred.unseal. do 2 split.
  - intros Hx. exact: principal_injN.
  - intros Hx. exact: principal_ne.
Qed.
End monotone.

Instance: Params (@principal) 1.
Arguments monotoneC : clear implicits.
Arguments monotoneR : clear implicits.