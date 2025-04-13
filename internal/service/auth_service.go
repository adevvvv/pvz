package service

import (
	"context"
	"errors"
	"pvz/internal/models"
	"pvz/internal/repository"
	"pvz/internal/utils"
)

type AuthService interface {
	Register(ctx context.Context, email, password string, role models.UserRole) (models.User, error)
	Login(ctx context.Context, email, password string) (string, error)
	DummyLogin(role models.UserRole) (string, error)
}

type authService struct {
	userRepo repository.UserRepository
}

func NewAuthService(userRepo repository.UserRepository) AuthService {
	return &authService{userRepo: userRepo}
}

func (s *authService) Register(ctx context.Context, email, password string, role models.UserRole) (models.User, error) {
	if role != models.Employee && role != models.Moderator {
		return models.User{}, errors.New("invalid role")
	}

	return s.userRepo.CreateUser(ctx, email, password, role)
}

func (s *authService) Login(ctx context.Context, email, password string) (string, error) {
	user, err := s.userRepo.GetUserByEmail(ctx, email)
	if err != nil {
		return "", errors.New("invalid credentials")
	}

	err = utils.CompareHashAndPassword(user.PasswordHash, password)
	if err != nil {
		return "", errors.New("invalid credentials")
	}

	return utils.GenerateToken(user.Email, string(user.Role))
}

func (s *authService) DummyLogin(role models.UserRole) (string, error) {
	if role != models.Employee && role != models.Moderator {
		return "", errors.New("invalid role")
	}

	return utils.GenerateToken("dummy@example.com", string(role))
}